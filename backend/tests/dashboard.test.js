const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../src/app');
const User = require('../src/models/User');
const Department = require('../src/models/Department');
const Doctor = require('../src/models/Doctor');
const QueueToken = require('../src/models/QueueToken');
const { getDashboard } = require('../src/services/dashboard.service');
const { issueAccessToken } = require('../src/services/token.service');

const userId = '507f1f77bcf86cd799439011';
let server;
let base;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api/staff/dashboard`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  t.mock.method(Date, 'now', () => Date.parse('2026-10-18T19:00:00Z'));
  const state = { role: 'admin', departments: 3, doctors: [{ total: 5, available: 4 }],
    tokens: [{ _id: 'waiting', count: 4 }, { _id: 'called', count: 1 },
      { _id: 'completed', count: 3 }, { _id: 'cancelled', count: 2 }] };
  t.mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => ({
    _id: userId, role: state.role, emailVerifiedAt: new Date(), tokenVersion: 0,
  }) }) }));
  const departments = t.mock.method(Department, 'countDocuments', async () => {
    if (state.error) throw state.error;
    return state.departments;
  });
  const doctors = t.mock.method(Doctor, 'aggregate', async () => state.doctors);
  const tokens = t.mock.method(QueueToken, 'aggregate', async () => state.tokens);
  const secret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (secret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = secret;
  });
  return { state, departments, doctors, tokens };
}

function get(query = '', token) {
  return fetch(base + query, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
}

test('dashboard requires auth and permits only admin and receptionist', async (t) => {
  const { state, tokens } = setup(t);
  assert.equal((await get()).status, 401);
  for (const role of ['patient', 'doctor']) {
    state.role = role;
    assert.equal((await get('', issueAccessToken(userId))).status, 403);
  }
  assert.equal(tokens.mock.callCount(), 0);
  for (const role of ['admin', 'receptionist']) {
    state.role = role;
    assert.equal((await get('', issueAccessToken(userId))).status, 200);
  }
});

test('dashboard returns safe counts with India date and all token statuses', async (t) => {
  const { tokens, doctors } = setup(t);
  const response = await get('', issueAccessToken(userId));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await response.json(), { success: true, data: {
    date: '2026-10-19', departments: 3, doctors: { total: 5, available: 4 },
    tokens: { total: 10, waiting: 4, called: 1, completed: 3, cancelled: 2, skipped: 0 },
  } });
  assert.deepEqual(tokens.mock.calls[0].arguments[0][0], { $match: { queueDate: '2026-10-19' } });
  assert.deepEqual(doctors.mock.calls[0].arguments[0][0].$group.available,
    { $sum: { $cond: [{ $eq: ['$isAvailable', true] }, 1, 0] } });
});

test('explicit date filters tokens without changing directory counts', async (t) => {
  const { tokens } = setup(t);
  const result = await getDashboard({ date: '2024-02-29' });
  assert.equal(result.date, '2024-02-29');
  assert.equal(result.doctors.total, 5);
  assert.deepEqual(tokens.mock.calls[0].arguments[0][0], { $match: { queueDate: '2024-02-29' } });
});

test('empty database and missing statuses return zero counters', async (t) => {
  const { state } = setup(t);
  state.departments = 0;
  state.doctors = [];
  state.tokens = [];
  const result = await getDashboard({});
  assert.equal(result.departments, 0);
  assert.deepEqual(result.doctors, { total: 0, available: 0 });
  assert.deepEqual(result.tokens, { total: 0, waiting: 0, called: 0, completed: 0, cancelled: 0, skipped: 0 });
  state.tokens = [{ _id: 'completed', count: 2 }];
  assert.deepEqual((await getDashboard({})).tokens,
    { total: 2, waiting: 0, called: 0, completed: 2, cancelled: 0, skipped: 0 });
});

test('dashboard includes skipped tokens as a separate status in the total', async (t) => {
  const { state } = setup(t);
  state.tokens.push({ _id: 'skipped', count: 2 });
  const result = await getDashboard({});
  assert.equal(result.tokens.skipped, 2);
  assert.equal(result.tokens.completed, 3);
  assert.equal(result.tokens.cancelled, 2);
  assert.equal(result.tokens.total, 12);
});

test('invalid dates, duplicate dates and query overrides fail before database reads', async (t) => {
  const { departments, tokens } = setup(t);
  for (const query of [{ date: '2026-02-30' }, { date: '2025-02-29' }, { date: 'bad' },
    { date: '' }, { date: ['2026-10-18'] }, { date: { $ne: null } },
    { doctorId: userId }, { role: 'admin' }]) {
    await assert.rejects(getDashboard(query), { code: 'VALIDATION_ERROR' });
  }
  const response = await get('?date=2026-10-18&date=2026-10-19', issueAccessToken(userId));
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, 'VALIDATION_ERROR');
  assert.equal(departments.mock.callCount(), 0);
  assert.equal(tokens.mock.callCount(), 0);
});

test('database failure produces a safe 500 and token counting has a supporting index', async (t) => {
  const { state } = setup(t);
  state.error = new Error('Private database connection string');
  const response = await get('', issueAccessToken(userId));
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.message, 'An unexpected error occurred.');
  assert.ok(QueueToken.schema.indexes().some(([fields]) => fields.queueDate === 1 && fields.status === 1));
});
