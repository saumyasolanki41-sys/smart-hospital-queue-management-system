const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../src/app');
const User = require('../src/models/User');
const google = require('../src/services/google.service');
const service = require('../src/services/google-login.service');
const { issueAccessToken } = require('../src/services/token.service');

const userId = '507f1f77bcf86cd799439011';
let server;
let base;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api/auth/google/link`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  const state = { user: { _id: userId, email: 'patient@gmail.com', name: 'Test Patient', role: 'patient',
    emailVerifiedAt: new Date(), tokenVersion: 0, passwordHash: '$2b$12$' + 'a'.repeat(53) },
    identity: { googleSubject: 'google-link-123', email: 'patient@gmail.com', name: 'Google Name' } };
  t.mock.method(User, 'init', async () => {});
  t.mock.method(User, 'findById', () => ({ select: () => ({
    lean: async () => state.user,
    then: (resolve, reject) => Promise.resolve(state.user).then(resolve, reject),
  }) }));
  t.mock.method(User, 'findOne', async () => state.user);
  const verify = t.mock.method(google, 'verifyGoogleToken', async () => {
    if (state.verifyError) throw state.verifyError;
    return state.identity;
  });
  const update = t.mock.method(User, 'updateOne', async (filter, change) => {
    if (state.writeError) throw state.writeError;
    if (state.race) return { modifiedCount: 0 };
    state.user.googleSubject = change.$set.googleSubject;
    return { modifiedCount: 1 };
  });
  const previous = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (previous === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = previous;
  });
  return { state, update, verify };
}

function post(body, token, type = 'application/json') {
  return fetch(base, { method: 'POST', headers: { 'Content-Type': type,
    ...(token ? { Authorization: 'Bearer ' + token } : {}) }, body: JSON.stringify(body) });
}

test('Google linking requires a valid existing session before Google token verification', async (t) => {
  const { verify, update } = setup(t);
  assert.equal((await post({ idToken: 'test-google-token' })).status, 401);
  assert.equal((await post({ idToken: 'test-google-token' }, 'bad-token')).status, 401);
  assert.equal(verify.mock.callCount(), 0);
  assert.equal(update.mock.callCount(), 0);
});

test('verified matching identity links the current account and preserves password, profile and role', async (t) => {
  const { state, update } = setup(t);
  state.user.role = 'doctor';
  const previous = { ...state.user };
  const response = await post({ idToken: 'test-google-token' }, issueAccessToken(userId));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual((await response.json()).data, { googleLinked: true,
    message: 'Google linked successfully. You can now sign in with Google.' });
  assert.deepEqual(state.user, { ...previous, googleSubject: state.identity.googleSubject });
  const [filter, changes, options] = update.mock.calls[0].arguments;
  assert.equal(filter._id, userId);
  assert.equal(filter.email, previous.email);
  assert.deepEqual(filter.googleSubject, { $exists: false });
  assert.deepEqual(changes, { $set: { googleSubject: state.identity.googleSubject } });
  assert.equal(options.overwriteImmutable, true);
  const login = await service.googleLogin({ idToken: 'test-google-token' });
  assert.equal(login.user.id, userId);
  assert.equal(login.user.role, 'doctor');
});

test('mismatching Google email never links or changes the current account', async (t) => {
  const { state, update } = setup(t);
  state.identity.email = 'different@gmail.com';
  await assert.rejects(service.linkGoogle(userId, { idToken: 'test-google-token' }), { code: 'GOOGLE_EMAIL_MISMATCH' });
  assert.equal(update.mock.callCount(), 0);
});

test('invalid token and client-selected account or role fields are rejected', async (t) => {
  const { state, verify, update } = setup(t);
  for (const body of [null, [], {}, { idToken: 'x', role: 'admin' }, { idToken: 'x', userId }]) {
    await assert.rejects(service.linkGoogle(userId, body), { code: 'INVALID_INPUT' });
  }
  assert.equal(verify.mock.callCount(), 0);
  state.verifyError = Object.assign(new Error('Google token invalid'), { status: 401, code: 'INVALID_GOOGLE_TOKEN' });
  const response = await post({ idToken: 'bad-google-token' }, issueAccessToken(userId));
  assert.equal(response.status, 401);
  assert.equal(update.mock.callCount(), 0);
});

test('repeated link of the same Google identity is idempotent and another identity cannot replace it', async (t) => {
  const { state, update } = setup(t);
  state.user.googleSubject = state.identity.googleSubject;
  assert.equal((await service.linkGoogle(userId, { idToken: 'x' })).googleLinked, true);
  state.identity.googleSubject = 'another-google-subject';
  await assert.rejects(service.linkGoogle(userId, { idToken: 'x' }), { code: 'GOOGLE_ALREADY_LINKED' });
  assert.equal(update.mock.callCount(), 0);
});

test('unique identity conflict and changed account produce safe conflicts', async (t) => {
  const { state } = setup(t);
  state.writeError = { code: 11000 };
  await assert.rejects(service.linkGoogle(userId, { idToken: 'x' }), { code: 'GOOGLE_ACCOUNT_IN_USE' });
  state.writeError = null;
  state.race = true;
  await assert.rejects(service.linkGoogle(userId, { idToken: 'x' }), { code: 'ACCOUNT_CHANGED' });
});

test('deleted/unverified accounts cannot link and unexpected database failures stay private', async (t) => {
  const { state } = setup(t);
  const previous = state.user;
  state.user = null;
  await assert.rejects(service.linkGoogle(userId, { idToken: 'x' }), { code: 'UNAUTHORIZED' });
  state.user = { ...previous, emailVerifiedAt: null };
  await assert.rejects(service.linkGoogle(userId, { idToken: 'x' }), { code: 'UNAUTHORIZED' });
  state.user = previous;
  state.writeError = new Error('Private database details');
  const response = await post({ idToken: 'x' }, issueAccessToken(userId));
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.message, 'An unexpected error occurred.');
});

test('linking rejects non-JSON input and Google identity remains immutable by default', async (t) => {
  const { verify } = setup(t);
  assert.equal((await post({ idToken: 'x' }, issueAccessToken(userId), 'text/plain')).status, 415);
  assert.equal(verify.mock.callCount(), 0);
  assert.equal(User.schema.path('googleSubject').options.immutable, true);
});
