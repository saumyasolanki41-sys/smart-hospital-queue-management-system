const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../src/app');
const Doctor = require('../src/models/Doctor');
const User = require('../src/models/User');
const QueueToken = require('../src/models/QueueToken');
const service = require('../src/services/staff-queue.service');
const { issueAccessToken } = require('../src/services/token.service');

const userId = '507f1f77bcf86cd799439011';
const doctorId = '507f1f77bcf86cd799439012';
const tokenId = '507f1f77bcf86cd799439013';
const staff = { id: userId, role: 'admin' };
let server;
let base;

before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api/staff/queues/doctors/${doctorId}`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  t.mock.method(Date, 'now', () => Date.parse('2026-10-18T19:00:00Z'));
  const state = {
    role: 'admin', doctor: { _id: doctorId, user: userId }, busy: false, exists: true,
    token: { _id: tokenId, doctor: doctorId, patient: { _id: userId, name: 'Test Patient' },
      queueDate: '2026-10-19', tokenNumber: 1, status: 'called' },
  };
  function query(value) {
    const chain = {};
    for (const method of ['select', 'populate', 'sort', 'skip', 'limit']) {
      chain[method] = t.mock.fn(() => chain);
    }
    chain.lean = async () => {
      if (state.error) throw state.error;
      return value();
    };
    return chain;
  }
  const findDoctor = t.mock.method(Doctor, 'findById', () => query(() => state.doctor));
  t.mock.method(User, 'findById', () => query(() => ({
    _id: userId, role: state.role, name: 'Test Staff', emailVerifiedAt: new Date(), tokenVersion: 0,
  })));
  t.mock.method(QueueToken, 'init', async () => {});
  const exists = t.mock.method(QueueToken, 'exists', async (filter) => filter._id ? state.exists : state.busy);
  const list = query(() => [state.token]);
  const find = t.mock.method(QueueToken, 'find', () => list);
  const findOne = t.mock.method(QueueToken, 'findOne', () => query(() => state.busy ? state.token : null));
  const write = t.mock.method(QueueToken, 'findOneAndUpdate', () => {
    if (state.writeError) throw state.writeError;
    return query(() => state.token);
  });
  const secret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (secret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = secret;
  });
  return { state, findDoctor, exists, list, find, findOne, write };
}

async function request(path, method = 'GET', data, token) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (data !== undefined) headers['Content-Type'] = 'application/json';
  return fetch(base + path, { method, headers, body: data === undefined ? undefined : JSON.stringify(data) });
}

test('staff routes reject missing tokens and patient accounts before queue writes', async (t) => {
  const { state, write } = setup(t);
  for (const [path, method] of [['/tokens', 'GET'], ['/call-next', 'POST'], [`/tokens/${tokenId}/complete`, 'PATCH']]) {
    assert.equal((await request(path, method)).status, 401);
    state.role = 'patient';
    assert.equal((await request(path, method, undefined, issueAccessToken(userId))).status, 403);
  }
  assert.equal(write.mock.callCount(), 0);
});

test('admin and receptionist can view any queue; doctors can view only their linked profile', async (t) => {
  const { state, find, list } = setup(t);
  for (const role of ['admin', 'receptionist', 'doctor']) {
    state.role = role;
    const response = await request('/tokens?page=2&limit=5', 'GET', undefined, issueAccessToken(userId));
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
  }
  assert.deepEqual(find.mock.calls[0].arguments[0], { doctor: doctorId, queueDate: '2026-10-19', status: 'waiting' });
  assert.equal(list.skip.mock.calls[0].arguments[0], 5);
  assert.deepEqual(list.populate.mock.calls[0].arguments, ['patient', 'name']);
  state.doctor.user = '507f1f77bcf86cd799439099';
  assert.equal((await request('/tokens', 'GET', undefined, issueAccessToken(userId))).status, 403);
  state.doctor.user = undefined;
  assert.equal((await request('/tokens', 'GET', undefined, issueAccessToken(userId))).status, 403);
});

test('doctor cannot call or complete a token in another doctor queue', async (t) => {
  const { state, write } = setup(t);
  state.doctor.user = '507f1f77bcf86cd799439099';
  const doctor = { id: userId, role: 'doctor' };
  await assert.rejects(service.callNext(doctor, doctorId), { code: 'FORBIDDEN' });
  await assert.rejects(service.completeToken(doctor, doctorId, tokenId), { code: 'FORBIDDEN' });
  assert.equal(write.mock.callCount(), 0);
});

test('call-next atomically selects the lowest waiting number for today', async (t) => {
  const { write } = setup(t);
  const response = await request('/call-next', 'POST', {}, issueAccessToken(userId));
  assert.equal(response.status, 200);
  assert.equal((await response.json()).data.token.status, 'called');
  const [filter, update, options] = write.mock.calls[0].arguments;
  assert.deepEqual(filter, { doctor: doctorId, queueDate: '2026-10-19', status: 'waiting', active: true });
  assert.equal(update.$set.status, 'called');
  assert.ok(update.$set.calledAt instanceof Date);
  assert.deepEqual(options.sort, { tokenNumber: 1 });
  assert.equal(options.returnDocument, 'after');
  assert.equal(options.runValidators, true);
});

test('a current called token blocks the next call even from an earlier queue day', async (t) => {
  const { state, write, exists } = setup(t);
  state.busy = true;
  state.token.queueDate = '2026-10-18';
  await assert.rejects(service.callNext(staff, doctorId), { code: 'QUEUE_BUSY' });
  assert.deepEqual(exists.mock.calls[0].arguments[0], { doctor: doctorId, status: 'called' });
  assert.equal(write.mock.callCount(), 0);
});

test('concurrent call unique-index conflict returns 409 and an empty queue is explicit', async (t) => {
  const { state } = setup(t);
  state.writeError = { code: 11000 };
  const response = await request('/call-next', 'POST', {}, issueAccessToken(userId));
  assert.equal(response.status, 409);
  assert.equal((await response.json()).error.code, 'QUEUE_BUSY');
  state.writeError = undefined;
  state.token = null;
  await assert.rejects(service.callNext(staff, doctorId), { code: 'QUEUE_EMPTY' });
});

test('completion requires matching doctor and called status and releases the active booking', async (t) => {
  const { state, write } = setup(t);
  state.token.status = 'completed';
  const response = await request(`/tokens/${tokenId}/complete`, 'PATCH', undefined, issueAccessToken(userId));
  assert.equal(response.status, 200);
  const [filter, update] = write.mock.calls[0].arguments;
  assert.deepEqual(filter, { _id: tokenId, doctor: doctorId, status: 'called', active: true });
  assert.equal(update.$set.status, 'completed');
  assert.equal(update.$set.active, false);
  assert.ok(update.$set.completedAt instanceof Date);
});

test('repeated completion and invalid state return 409; absent or wrong-doctor token returns 404', async (t) => {
  const { state } = setup(t);
  state.token = null;
  await assert.rejects(service.completeToken(staff, doctorId, tokenId), { code: 'TOKEN_NOT_CALLED' });
  state.exists = false;
  await assert.rejects(service.completeToken(staff, doctorId, tokenId), { code: 'TOKEN_NOT_FOUND' });
});

test('malformed IDs, body overrides and invalid filters never reach token writes', async (t) => {
  const { write } = setup(t);
  await assert.rejects(service.callNext(staff, 'bad'), { code: 'VALIDATION_ERROR' });
  await assert.rejects(service.completeToken(staff, doctorId, 'bad'), { code: 'VALIDATION_ERROR' });
  for (const body of [null, [], { tokenNumber: 20 }, { patientId: userId }, { status: 'completed' }]) {
    await assert.rejects(service.callNext(staff, doctorId, body), { code: 'VALIDATION_ERROR' });
    await assert.rejects(service.completeToken(staff, doctorId, tokenId, body), { code: 'VALIDATION_ERROR' });
  }
  for (const query of [{ status: 'bad' }, { status: ['waiting'] }, { page: '0' },
    { limit: '51' }, { date: '2026-10-18' }, { patientId: userId }]) {
    await assert.rejects(service.listQueue(staff, doctorId, query), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(write.mock.callCount(), 0);
});

test('missing doctor returns 404 and database details remain private', async (t) => {
  const { state } = setup(t);
  state.doctor = null;
  await assert.rejects(service.callNext(staff, doctorId), { code: 'DOCTOR_NOT_FOUND' });
  state.error = new Error('Private database details');
  const response = await request('/tokens', 'GET', undefined, issueAccessToken(userId));
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.message, 'An unexpected error occurred.');
});

test('a partial unique index enforces one called token per doctor across all dates', () => {
  const index = QueueToken.schema.indexes().find(([fields, options]) =>
    fields.doctor === 1 && options.partialFilterExpression?.status === 'called');
  assert.ok(index);
  assert.equal(index[1].unique, true);
  assert.equal(index[0].queueDate, undefined);
  assert.equal(QueueToken.schema.path('calledAt').instance, 'Date');
  assert.equal(QueueToken.schema.path('completedAt').instance, 'Date');
});
