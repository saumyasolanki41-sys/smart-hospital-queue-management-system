const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const mongoose = require('mongoose');
const app = require('../src/app');
const Doctor = require('../src/models/Doctor');
const User = require('../src/models/User');
const QueueDay = require('../src/models/QueueDay');
const QueueToken = require('../src/models/QueueToken');
const service = require('../src/services/queue.service');
const { issueAccessToken } = require('../src/services/token.service');

const patientId = '507f1f77bcf86cd799439011';
const doctorId = '507f1f77bcf86cd799439012';
const tokenId = '507f1f77bcf86cd799439013';
const body = { doctorId };
let server;
let base;

before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  const now = Date.parse('2026-10-18T19:00:00Z');
  t.mock.method(Date, 'now', () => now);
  const state = {
    role: 'patient', doctor: { _id: doctorId, isAvailable: true }, duplicate: false,
    day: { lastToken: 1 },
    token: { _id: tokenId, doctor: doctorId, patient: patientId,
      queueDate: '2026-10-19', tokenNumber: 1, status: 'waiting', active: true, createdAt: new Date(now) },
    ahead: 2, owned: true, current: null,
  };
  const session = {};
  function query(value) {
    const chain = {};
    for (const method of ['select', 'populate', 'sort', 'skip', 'limit']) {
      chain[method] = t.mock.fn(() => chain);
    }
    chain.lean = async () => value();
    chain.session = async () => value();
    chain.then = (resolve, reject) => Promise.resolve().then(value).then(resolve, reject);
    return chain;
  }
  const findDoctor = t.mock.method(Doctor, 'findById', () => query(() => state.doctor));
  t.mock.method(QueueDay, 'init', async () => {});
  t.mock.method(QueueToken, 'init', async () => {});
  const initializeDay = t.mock.method(QueueDay, 'updateOne', async () => {
    if (state.initError) throw state.initError;
  });
  const counter = t.mock.method(QueueDay, 'findByIdAndUpdate', async () => state.day);
  const exists = t.mock.method(QueueToken, 'exists', (filter) =>
    query(() => filter._id ? state.owned : state.duplicate));
  const create = t.mock.method(QueueToken, 'create', async () => {
    if (state.createError) throw state.createError;
    return [state.token];
  });
  const findOne = t.mock.method(QueueToken, 'findOne', (filter) =>
    query(() => filter.status === 'called' ? state.current : state.token));
  const list = query(() => [state.token]);
  const find = t.mock.method(QueueToken, 'find', () => list);
  const count = t.mock.method(QueueToken, 'countDocuments', async () => state.ahead);
  const cancel = t.mock.method(QueueToken, 'findOneAndUpdate', () => query(() => state.cancelMiss ? null : state.token));
  const transaction = t.mock.method(mongoose.connection, 'transaction', async (callback) => callback(session));
  t.mock.method(User, 'findById', () => query(() => ({
    _id: patientId, role: state.role, emailVerifiedAt: new Date(), tokenVersion: 0,
  })));
  const secret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (secret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = secret;
  });
  return { state, session, findDoctor, initializeDay, counter, exists, create, findOne,
    list, find, count, cancel, transaction };
}

async function request(path, method = 'GET', data, token) {
  const headers = {};
  if (data !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(base + '/api/queue' + path, {
    method, headers, body: data === undefined ? undefined : JSON.stringify(data),
  });
}

test('all queue endpoints require authentication and a patient account', async (t) => {
  const { state, create, cancel } = setup(t);
  for (const [path, method, data] of [
    ['/tokens', 'POST', body], ['/tokens/mine', 'GET'], ['/tokens/' + tokenId, 'GET'],
    ['/tokens/' + tokenId + '/cancel', 'PATCH'],
  ]) {
    assert.equal((await request(path, method, data)).status, 401);
    for (const role of ['admin', 'doctor', 'receptionist']) {
      state.role = role;
      assert.equal((await request(path, method, data, issueAccessToken(patientId))).status, 403);
    }
  }
  assert.equal(create.mock.callCount(), 0);
  assert.equal(cancel.mock.callCount(), 0);
});

test('patient booking returns 201 and assigns only server-controlled token fields', async (t) => {
  const { create, session, counter, transaction } = setup(t);
  const response = await request('/tokens', 'POST', body, issueAccessToken(patientId));
  assert.equal(response.status, 201);
  const result = (await response.json()).data.token;
  assert.equal(result.tokenNumber, 1);
  assert.equal(result.queueDate, '2026-10-19');
  assert.equal(result.patient, undefined);
  assert.equal(result.active, undefined);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  const [documents, options] = create.mock.calls[0].arguments;
  assert.equal(documents[0].patient, patientId);
  assert.equal(documents[0].doctor, doctorId);
  assert.equal(documents[0].status, 'waiting');
  assert.equal(options.session, session);
  assert.equal(counter.mock.calls[0].arguments[0], doctorId + ':2026-10-19');
  assert.deepEqual(counter.mock.calls[0].arguments[1], { $inc: { lastToken: 1 } });
  assert.equal(counter.mock.calls[0].arguments[2].session, session);
  assert.equal(transaction.mock.calls[0].arguments[1].writeConcern.w, 'majority');
});

test('invalid IDs and caller-supplied patient, status, date or token number fail before reads', async (t) => {
  const { findDoctor } = setup(t);
  for (const data of [null, [], {}, { doctorId: 'bad' }, { doctorId: { $ne: null } },
    { ...body, patientId }, { ...body, status: 'called' },
    { ...body, tokenNumber: 1 }, { ...body, date: '2026-10-19' }]) {
    await assert.rejects(service.joinQueue(patientId, data), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(findDoctor.mock.callCount(), 0);
});

test('missing or unavailable doctors cannot get new bookings', async (t) => {
  const { state, counter } = setup(t);
  state.doctor = null;
  await assert.rejects(service.joinQueue(patientId, body), { code: 'DOCTOR_NOT_FOUND' });
  state.doctor = { isAvailable: false };
  await assert.rejects(service.joinQueue(patientId, body), { code: 'DOCTOR_UNAVAILABLE' });
  assert.equal(counter.mock.callCount(), 0);
});

test('existing active booking is rejected without allocating another number', async (t) => {
  const { state, counter, exists } = setup(t);
  state.duplicate = true;
  await assert.rejects(service.joinQueue(patientId, body), { code: 'ALREADY_IN_QUEUE' });
  assert.equal(exists.mock.calls[0].arguments[0].patient, patientId);
  assert.equal(exists.mock.calls[0].arguments[0].active, true);
  assert.equal(counter.mock.callCount(), 0);
});

test('first counter initialization race is tolerated and token insertion conflicts are safe', async (t) => {
  const { state } = setup(t);
  state.initError = { code: 11000 };
  await service.joinQueue(patientId, body);
  state.createError = { code: 11000 };
  await assert.rejects(service.joinQueue(patientId, body), { code: 'QUEUE_CONFLICT' });
});

test('insert failure propagates out of transaction callback for rollback', async (t) => {
  const { state, transaction } = setup(t);
  state.createError = new Error('Database write failed');
  await assert.rejects(service.joinQueue(patientId, body), /Database write failed/);
  assert.equal(transaction.mock.callCount(), 1);
});

test('availability is rechecked inside the transaction', async (t) => {
  const { findDoctor, counter } = setup(t);
  findDoctor.mock.mockImplementation(() => ({ select: () => ({
    lean: async () => ({ isAvailable: true }), session: async () => ({ isAvailable: false }),
  }) }));
  await assert.rejects(service.joinQueue(patientId, body), { code: 'DOCTOR_UNAVAILABLE' });
  assert.equal(counter.mock.callCount(), 0);
});

test('midnight rollover during booking asks the client to retry', async (t) => {
  const { transaction, counter } = setup(t);
  transaction.mock.mockImplementation(async (callback) => {
    Date.now.mock.mockImplementation(() => Date.parse('2026-10-19T19:00:00Z'));
    return callback({});
  });
  await assert.rejects(service.joinQueue(patientId, body), { code: 'QUEUE_DAY_CHANGED' });
  assert.equal(counter.mock.callCount(), 0);
});

test('mine list is scoped to logged-in patient and a valid date with bounded pagination', async (t) => {
  const { find, list } = setup(t);
  const result = await service.myTokens(patientId, { date: '2026-10-18', page: '2', limit: '5' });
  assert.equal(result.page, 2);
  assert.deepEqual(find.mock.calls[0].arguments[0], { patient: patientId, queueDate: '2026-10-18' });
  assert.equal(list.skip.mock.calls[0].arguments[0], 5);
  assert.equal(list.limit.mock.calls[0].arguments[0], 5);
  for (const query of [{ date: '2026-02-30' }, { date: 'bad' }, { date: ['2026-01-01'] },
    { page: '0' }, { limit: '51' }, { patientId: 'other' }]) {
    await assert.rejects(service.myTokens(patientId, query), { code: 'VALIDATION_ERROR' });
  }
});

test('status hides other patients tokens and returns only the waiting count ahead', async (t) => {
  const { state, findOne, count } = setup(t);
  const result = await service.tokenStatus(patientId, tokenId);
  assert.equal(result.peopleAhead, 2);
  assert.deepEqual(findOne.mock.calls[0].arguments[0], { _id: tokenId, patient: patientId });
  assert.deepEqual(count.mock.calls[0].arguments[0].tokenNumber, { $lt: 1 });
  state.token = null;
  await assert.rejects(service.tokenStatus(patientId, tokenId), { code: 'TOKEN_NOT_FOUND' });
});

test('historical and terminal tokens do not report a live queue position', async (t) => {
  const { state, count } = setup(t);
  state.token.queueDate = '2026-10-18';
  assert.equal((await service.tokenStatus(patientId, tokenId)).peopleAhead, null);
  state.token.queueDate = '2026-10-19';
  state.token.status = 'cancelled';
  assert.equal((await service.tokenStatus(patientId, tokenId)).peopleAhead, null);
  assert.equal(count.mock.callCount(), 0);
});

test('cancellation atomically checks patient and waiting status and frees active booking', async (t) => {
  const { cancel } = setup(t);
  await service.cancelToken(patientId, tokenId, {});
  const [filter, update] = cancel.mock.calls[0].arguments;
  assert.deepEqual(filter, { _id: tokenId, patient: patientId, status: 'waiting', active: true });
  assert.deepEqual(update, { $set: { status: 'cancelled', active: false } });
  await assert.rejects(service.cancelToken(patientId, tokenId, { patientId: 'other' }), { code: 'VALIDATION_ERROR' });
});

test('another patient gets 404 and non-waiting or cancelled tokens get 409 on cancellation', async (t) => {
  const { state } = setup(t);
  state.cancelMiss = true;
  state.owned = false;
  await assert.rejects(service.cancelToken(patientId, tokenId), { code: 'TOKEN_NOT_FOUND' });
  state.owned = true;
  await assert.rejects(service.cancelToken(patientId, tokenId), { code: 'TOKEN_NOT_CANCELLABLE' });
});

test('token indexes enforce daily uniqueness and one active booking per patient and doctor', async () => {
  const indexes = QueueToken.schema.indexes();
  assert.ok(indexes.some(([fields, options]) => fields.tokenNumber === 1 && options.unique));
  const active = indexes.find(([fields]) => fields.patient === 1 && fields.doctor === 1);
  assert.equal(active[1].unique, true);
  assert.deepEqual(active[1].partialFilterExpression, { active: true });
  await new QueueToken({ patient: patientId, doctor: doctorId, queueDate: '2026-10-19', tokenNumber: 1 }).validate();
  await assert.rejects(new QueueToken({ patient: patientId, doctor: doctorId, queueDate: '2026-10-19', tokenNumber: 0 }).validate());
});

test('waiting estimate uses configured duration plus remaining current consultation time', async (t) => {
  const { state, findOne } = setup(t);
  state.doctor.averageConsultationMinutes = 12;
  state.ahead = 3;
  state.current = { calledAt: new Date(Date.now() - 5 * 60000), patient: 'private-patient-id' };
  const response = await request('/tokens/' + tokenId, 'GET', undefined, issueAccessToken(patientId));
  assert.equal(response.status, 200);
  const result = (await response.json()).data;
  assert.equal(result.estimatedWaitMinutes, 43);
  assert.equal(result.averageConsultationMinutes, 12);
  assert.equal(result.consultationOverdue, false);
  assert.equal(result.current, undefined);
  assert.deepEqual(findOne.mock.calls[1].arguments[0], { doctor: doctorId, status: 'called' });
});

test('empty waiting queue without a current consultation estimates zero', async (t) => {
  const { state } = setup(t);
  state.ahead = 0;
  const result = await service.tokenStatus(patientId, tokenId);
  assert.equal(result.estimatedWaitMinutes, 0);
  assert.equal(result.averageConsultationMinutes, 10);
  assert.equal(result.consultationOverdue, false);
});

test('overdue consultations keep a minimum remaining minute and signal uncertainty', async (t) => {
  const { state } = setup(t);
  state.current = { calledAt: new Date(Date.now() - 20 * 60000) };
  const result = await service.tokenStatus(patientId, tokenId);
  assert.equal(result.estimatedWaitMinutes, 21);
  assert.equal(result.consultationOverdue, true);
});

test('missing or future consultation timestamps use a full configured duration', async (t) => {
  const { state } = setup(t);
  state.ahead = 0;
  for (const current of [{}, { calledAt: new Date(Date.now() + 60000) }, { calledAt: 'invalid' }]) {
    state.current = current;
    const result = await service.tokenStatus(patientId, tokenId);
    assert.equal(result.estimatedWaitMinutes, 10);
    assert.equal(result.consultationOverdue, false);
  }
});

test('historical, cancelled, called and completed tokens have no waiting estimate', async (t) => {
  const { state, findDoctor } = setup(t);
  for (const status of ['cancelled', 'called', 'completed', 'skipped']) {
    state.token.status = status;
    const result = await service.tokenStatus(patientId, tokenId);
    assert.equal(result.estimatedWaitMinutes, null);
    assert.equal(result.averageConsultationMinutes, null);
    assert.equal(result.consultationOverdue, null);
  }
  state.token.status = 'waiting';
  state.token.queueDate = '2026-10-18';
  assert.equal((await service.tokenStatus(patientId, tokenId)).estimatedWaitMinutes, null);
  assert.equal(findDoctor.mock.callCount(), 0);
});

test('legacy duration defaults to ten minutes and missing doctor gives no estimate', async (t) => {
  const { state } = setup(t);
  for (const duration of [undefined, 0, 121, 1.5]) {
    state.doctor.averageConsultationMinutes = duration;
    const result = await service.tokenStatus(patientId, tokenId);
    assert.equal(result.estimatedWaitMinutes, 20);
    assert.equal(result.averageConsultationMinutes, 10);
  }
  state.doctor = null;
  const result = await service.tokenStatus(patientId, tokenId);
  assert.equal(result.peopleAhead, 2);
  assert.equal(result.estimatedWaitMinutes, null);
});
