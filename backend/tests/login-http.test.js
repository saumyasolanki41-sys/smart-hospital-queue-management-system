const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../src/app');
const loginService = require('../src/services/login.service');
const { passwordLoginLimiter, loginVerificationLimiter } = require('../src/middleware/authLimiter');

let server;
let baseUrl;

before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

beforeEach(() => {
  passwordLoginLimiter.resetKey('127.0.0.1');
  loginVerificationLimiter.resetKey('127.0.0.1');
});

after(() => new Promise((resolve, reject) => {
  server.close((error) => error ? reject(error) : resolve());
}));

function post(path, body) {
  return fetch(`${baseUrl}${path}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

test('POST login returns a non-cacheable 202 challenge without JWT', async (t) => {
  const data = { challengeId: '507f1f77bcf86cd799439011', message: 'Login OTP sent.' };
  t.mock.method(loginService, 'requestLogin', async () => data);
  const response = await post('/api/auth/login', { email: 'patient@example.com', password: 'Test123!' });
  assert.equal(response.status, 202);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await response.json(), { success: true, data });
});

test('POST verification returns the verified login response', async (t) => {
  const data = { accessToken: 'test-only-token', tokenType: 'Bearer', expiresIn: 900 };
  t.mock.method(loginService, 'verifyLogin', async () => data);
  const response = await post('/api/auth/login/verify', {
    challengeId: '507f1f77bcf86cd799439011', otp: '001234',
  });
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await response.json(), { success: true, data });
});

test('login exposes only known service errors and adds cooldown Retry-After', async (t) => {
  let failure;
  t.mock.method(loginService, 'requestLogin', async () => { throw failure; });
  for (const [code, status] of [
    ['VALIDATION_ERROR', 400], ['INVALID_CREDENTIALS', 401],
    ['LOGIN_COOLDOWN', 429], ['EMAIL_UNAVAILABLE', 503],
  ]) {
    failure = Object.assign(new Error('Public message'), { code });
    const response = await post('/api/auth/login', {});
    assert.equal(response.status, status);
    assert.equal((await response.json()).error.code, code);
    if (status === 429) assert.equal(response.headers.get('retry-after'), '60');
  }
});

test('verification maps invalid OTP to 400 and hides internal database errors', async (t) => {
  let failure = Object.assign(new Error('Invalid OTP'), { code: 'INVALID_OR_EXPIRED_OTP' });
  t.mock.method(loginService, 'verifyLogin', async () => { throw failure; });
  let response = await post('/api/auth/login/verify', {});
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, 'INVALID_OR_EXPIRED_OTP');
  failure = new Error('Private database diagnostic');
  response = await post('/api/auth/login/verify', {});
  assert.equal(response.status, 500);
  assert.deepEqual(await response.json(), {
    success: false, error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred.' },
  });
});

test('password-login rate limit blocks the eleventh request before the service', async (t) => {
  const request = t.mock.method(loginService, 'requestLogin', async () => ({ message: 'Test' }));
  for (let i = 0; i < 10; i++) {
    const response = await post('/api/auth/login', {});
    assert.equal(response.status, 202);
    await response.json();
  }
  const response = await post('/api/auth/login', {});
  assert.equal(response.status, 429);
  assert.equal((await response.json()).error.code, 'RATE_LIMITED');
  assert.equal(request.mock.callCount(), 10);
});

test('verification rate limit is independent and blocks request thirty-one', async (t) => {
  const verify = t.mock.method(loginService, 'verifyLogin', async () => ({ message: 'Test' }));
  for (let i = 0; i < 30; i++) {
    const response = await post('/api/auth/login/verify', {});
    assert.equal(response.status, 200);
    await response.json();
  }
  const response = await post('/api/auth/login/verify', {});
  assert.equal(response.status, 429);
  assert.equal((await response.json()).error.code, 'RATE_LIMITED');
  assert.equal(verify.mock.callCount(), 30);
});
