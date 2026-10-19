const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const mongoose = require('mongoose');
const app = require('../src/app');
const Doctor = require('../src/models/Doctor');
const QueueToken = require('../src/models/QueueToken');
const User = require('../src/models/User');
const { getDoctorDashboard } = require('../src/services/dashboard.service');
const { issueAccessToken } = require('../src/services/token.service');

const userId = '507f1f77bcf86cd799439011';
const doctorId = new mongoose.Types.ObjectId('507f1f77bcf86cd799439012');
let server;
let base;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api/doctor/dashboard`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  t.mock.method(Date, 'now', () => Date.parse('2026-10-18T19:00:00Z'));
  const state = { role: 'doctor', doctor: { _id: doctorId, name: 'Dr Test', isAvailable: true },
    rows: [{ _id: 'waiting', count: 3 }, { _id: 'completed', count: 2 }, { _id: 'skipped', count: 1 }], current: null };
  function query(value) {
    const chain = {};
    for (const method of ['select', 'populate']) chain[method] = t.mock.fn(() => chain);
    chain.lean = async () => {
      if (state.error) throw state.error;
      return value();
    };
    return chain;
  }
  t.mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => ({
    _id: userId, role: state.role, emailVerifiedAt: new Date(), tokenVersion: 0,
  }) }) }));
  const profile = query(() => state.doctor);
  const doctor = t.mock.method(Doctor, 'findOne', () => profile);
  const aggregate = t.mock.method(QueueToken, 'aggregate', async () => state.rows);
  const tokenQuery = query(() => state.current);
  const current = t.mock.method(QueueToken, 'findOne', () => tokenQuery);
  const oldSecret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (oldSecret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = oldSecret;
  });
  return { state, doctor, profile, aggregate, current, tokenQuery };
}

function get(query = '', token) {
  return fetch(base + query, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
}

test('doctor summary requires a doctor login and blocks all other roles before lookup', async (t) => {
  const { state, doctor } = setup(t);
  assert.equal((await get()).status, 401);
  for (const role of ['patient', 'admin', 'receptionist']) {
    state.role = role;
    assert.equal((await get('', issueAccessToken(userId))).status, 403);
  }
  assert.equal(doctor.mock.callCount(), 0);
});

test('doctor summary scopes ObjectId aggregation and current patient to the linked profile', async (t) => {
  const { doctor, profile, aggregate, current, tokenQuery } = setup(t);
  const response = await get('', issueAccessToken(userId));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  const data = (await response.json()).data;
  assert.equal(data.date, '2026-10-19');
  assert.deepEqual(data.tokens, { total: 6, waiting: 3, called: 0, completed: 2, cancelled: 0, skipped: 1 });
  assert.equal(data.currentToken, null);
  assert.deepEqual(doctor.mock.calls[0].arguments[0], { user: userId });
  assert.deepEqual(aggregate.mock.calls[0].arguments[0][0], { $match: { doctor: doctorId, queueDate: '2026-10-19' } });
  assert.ok(aggregate.mock.calls[0].arguments[0][0].$match.doctor instanceof mongoose.Types.ObjectId);
  assert.deepEqual(current.mock.calls[0].arguments[0], { doctor: doctorId, status: 'called' });
  assert.deepEqual(tokenQuery.populate.mock.calls[0].arguments, ['patient', 'name']);
  assert.equal(profile.select.mock.calls[0].arguments[0].includes('user'), false);
});

test('unlinked doctor receives 404 without any token reads', async (t) => {
  const { state, aggregate, current } = setup(t);
  state.doctor = null;
  const response = await get('', issueAccessToken(userId));
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, 'DOCTOR_NOT_FOUND');
  assert.equal(aggregate.mock.callCount(), 0);
  assert.equal(current.mock.callCount(), 0);
});

test('historic counts keep the live called token, including previous-day consultations', async (t) => {
  const { state, current } = setup(t);
  state.rows = [];
  state.current = { _id: '507f1f77bcf86cd799439013', queueDate: '2026-10-18', status: 'called',
    patient: { _id: userId, name: 'Test Patient' } };
  const data = await getDoctorDashboard(userId, { date: '2024-02-29' });
  assert.equal(data.date, '2024-02-29');
  assert.deepEqual(data.tokens, { total: 0, waiting: 0, called: 0, completed: 0, cancelled: 0, skipped: 0 });
  assert.equal(data.currentToken.queueDate, '2026-10-18');
  assert.equal(current.mock.calls[0].arguments[0].queueDate, undefined);
});

test('doctor summary rejects date errors and profile overrides before database lookup', async (t) => {
  const { doctor } = setup(t);
  for (const query of [{ date: '2026-02-30' }, { date: '2025-02-29' }, { date: ['2026-10-19'] },
    { date: { $ne: null } }, { doctorId: doctorId.toString() }, { userId }, { role: 'admin' }]) {
    await assert.rejects(getDoctorDashboard(userId, query), { code: 'VALIDATION_ERROR' });
  }
  assert.equal((await get('?date=2026-10-18&date=2026-10-19', issueAccessToken(userId))).status, 400);
  assert.equal(doctor.mock.callCount(), 0);
});

test('doctor dashboard database failures return a generic error', async (t) => {
  const { state } = setup(t);
  state.error = new Error('Private database details');
  const response = await get('', issueAccessToken(userId));
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.message, 'An unexpected error occurred.');
});
