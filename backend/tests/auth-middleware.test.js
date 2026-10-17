const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const express = require('express');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const User = require('../src/models/User');
const tokenService = require('../src/services/token.service');
const { authenticate, allowRoles } = require('../src/middleware/auth.middleware');

const userId = '507f1f77bcf86cd799439011';
const secret = 'a'.repeat(64);
const roles = ['patient', 'doctor', 'receptionist', 'admin'];
let server;
let baseUrl;

before(async () => {
  const testApp = express();

  for (const role of roles) {
    testApp.get(`/test/${role}`, authenticate, allowRoles(role), (req, res) => {
      res.json({ role: req.user.role });
    });
  }

  testApp.get('/test/staff', authenticate,
    allowRoles('doctor', 'receptionist', 'admin'), (req, res) => {
      res.json({ role: req.user.role });
    });

  testApp.get('/test/no-authentication', allowRoles('admin'), (req, res) => {
    res.json({ success: true });
  });

  testApp.use(app);
  server = testApp.listen(0, '127.0.0.1');
  await once(server, 'listening');
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => new Promise((resolve, reject) => {
  server.close((error) => error ? reject(error) : resolve());
}));

function setup(t) {
  const oldSecret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = secret;

  t.after(() => {
    if (oldSecret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = oldSecret;
  });

  const state = {
    user: {
      _id: userId,
      name: 'Test Patient',
      email: 'patient@example.com',
      role: 'patient',
      emailVerifiedAt: new Date(),
      passwordHash: 'must-not-be-returned',
      googleSubject: 'must-not-be-returned',
    },
  };

  const select = t.mock.fn(() => ({
    lean: async () => {
      if (state.error) throw state.error;
      return state.user;
    },
  }));

  const find = t.mock.method(User, 'findById', () => ({ select }));

  return { state, find, select };
}

function makeToken(payload = {}, options = {}) {
  return jwt.sign(payload, Buffer.from(secret, 'hex'), {
    algorithm: 'HS256',
    subject: userId,
    issuer: 'hospital-queue-api',
    audience: 'hospital-queue-clients',
    expiresIn: '15m',
    ...options,
  });
}

function get(path, token) {
  const headers = {};
  if (token !== undefined) headers.Authorization = `Bearer ${token}`;
  return fetch(`${baseUrl}${path}`, { headers });
}

async function assertUnauthorized(response) {
  assert.equal(response.status, 401);
  assert.equal(response.headers.get('www-authenticate'), 'Bearer');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await response.json(), {
    success: false,
    error: { code: 'UNAUTHORIZED', message: 'A valid login token is required.' },
  });
}

test('GET me accepts an application access token and returns only the current safe profile', async (t) => {
  const { find, select } = setup(t);
  const token = tokenService.issueAccessToken(userId);
  const response = await get('/api/auth/me', token);

  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await response.json(), {
    success: true,
    data: { user: {
      id: userId, name: 'Test Patient', email: 'patient@example.com', role: 'patient',
    } },
  });
  assert.equal(find.mock.calls[0].arguments[0], userId);
  assert.equal(select.mock.calls[0].arguments[0], '_id name email role emailVerifiedAt tokenVersion');
});

test('password reset rejects old tokens and accepts a newly issued version', async (t) => {
  const { state } = setup(t);
  const oldToken = tokenService.issueAccessToken(userId);
  state.user.tokenVersion = 1;
  await assertUnauthorized(await get('/api/auth/me', oldToken));
  await assertUnauthorized(await get('/api/auth/me', makeToken()));
  assert.equal((await get('/api/auth/me', tokenService.issueAccessToken(userId, 1))).status, 200);
});

test('missing or malformed Authorization headers fail before database access', async (t) => {
  const { find } = setup(t);
  const headers = [undefined, '', 'Basic abc', 'Bearer', 'Bearer one two', 'Bearer ' + 'a'.repeat(8192)];

  for (const header of headers) {
    const response = await fetch(`${baseUrl}/api/auth/me`, {
      headers: header === undefined ? {} : { Authorization: header },
    });
    await assertUnauthorized(response);
  }

  assert.equal(find.mock.callCount(), 0);
});

test('Bearer scheme is case insensitive', async (t) => {
  setup(t);
  const response = await fetch(`${baseUrl}/api/auth/me`, {
    headers: { Authorization: `bearer ${makeToken()}` },
  });
  assert.equal(response.status, 200);
  await response.json();
});

test('malformed, tampered and wrong-key tokens fail without user lookup', async (t) => {
  const { find } = setup(t);
  const valid = makeToken();
  const wrongKey = jwt.sign({}, Buffer.from('b'.repeat(64), 'hex'), {
    subject: userId, issuer: 'hospital-queue-api', audience: 'hospital-queue-clients',
    expiresIn: '15m', algorithm: 'HS256',
  });

  for (const token of ['not-a-token', valid.slice(0, -8) + 'xxxxxxxx', wrongKey]) {
    await assertUnauthorized(await get('/api/auth/me', token));
  }

  assert.equal(find.mock.callCount(), 0);
});

test('expired, over-age and not-yet-active tokens are rejected', async (t) => {
  const { find } = setup(t);
  const now = Math.floor(Date.now() / 1000);
  const tokens = [
    makeToken({ iat: now - 901 }),
    makeToken({ iat: now - 901 }, { expiresIn: '1h' }),
    makeToken({}, { notBefore: '1h' }),
  ];

  for (const token of tokens) {
    await assertUnauthorized(await get('/api/auth/me', token));
  }

  assert.equal(find.mock.callCount(), 0);
});

test('wrong issuer, audience and signing algorithms are rejected', async (t) => {
  const { find } = setup(t);
  const tokens = [
    makeToken({}, { issuer: 'other-api' }),
    makeToken({}, { audience: 'other-client' }),
    makeToken({}, { algorithm: 'HS384' }),
    jwt.sign({ sub: userId }, null, { algorithm: 'none' }),
  ];

  for (const token of tokens) {
    await assertUnauthorized(await get('/api/auth/me', token));
  }

  assert.equal(find.mock.callCount(), 0);
});

test('expiry, issued-at time and a valid subject are mandatory', async (t) => {
  const { find } = setup(t);
  const key = Buffer.from(secret, 'hex');
  const now = Math.floor(Date.now() / 1000);
  const tokens = [
    jwt.sign({ sub: userId, iss: 'hospital-queue-api', aud: 'hospital-queue-clients' }, key),
    makeToken({}, { noTimestamp: true }),
    jwt.sign({ exp: now + 900, iss: 'hospital-queue-api', aud: 'hospital-queue-clients' }, key),
    makeToken({}, { subject: 'not-a-mongodb-id' }),
  ];

  for (const token of tokens) {
    await assertUnauthorized(await get('/api/auth/me', token));
  }

  assert.equal(find.mock.callCount(), 0);
});

test('tokens in query parameters are not accepted', async (t) => {
  const { find } = setup(t);
  await assertUnauthorized(await get(`/api/auth/me?accessToken=${makeToken()}`));
  assert.equal(find.mock.callCount(), 0);
});

test('deleted, unverified and unknown-role users are rejected', async (t) => {
  const { state } = setup(t);
  const user = state.user;

  for (const candidate of [null, { ...user, emailVerifiedAt: null }, { ...user, role: 'owner' }]) {
    state.user = candidate;
    await assertUnauthorized(await get('/api/auth/me', makeToken()));
  }
});

test('database failure returns a generic 500 without private diagnostics', async (t) => {
  const { state } = setup(t);
  state.error = new Error('Private database diagnostic');
  const response = await get('/api/auth/me', makeToken());
  assert.equal(response.status, 500);
  assert.deepEqual(await response.json(), {
    success: false, error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred.' },
  });
});

test('missing JWT configuration is a server error rather than an invalid-user error', async (t) => {
  const { find } = setup(t);
  const token = makeToken();
  delete process.env.JWT_SECRET;
  const response = await get('/api/auth/me', token);
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.code, 'INTERNAL_ERROR');
  assert.equal(find.mock.callCount(), 0);
});

test('each role can access its explicit route and other roles receive 403', async (t) => {
  const { state } = setup(t);
  const token = makeToken();

  for (const actualRole of roles) {
    state.user.role = actualRole;
    for (const allowedRole of roles) {
      const response = await get(`/test/${allowedRole}`, token);
      if (actualRole === allowedRole) {
        assert.equal(response.status, 200);
        assert.equal((await response.json()).role, actualRole);
      } else {
        assert.equal(response.status, 403);
        assert.equal((await response.json()).error.code, 'FORBIDDEN');
      }
    }
  }
});

test('staff allow-list accepts doctor, receptionist and admin but not patient', async (t) => {
  const { state } = setup(t);
  for (const role of roles) {
    state.user.role = role;
    const response = await get('/test/staff', makeToken());
    assert.equal(response.status, role === 'patient' ? 403 : 200);
    await response.json();
  }
});

test('token role claims and client-supplied roles do not grant staff access', async (t) => {
  setup(t);
  const response = await fetch(`${baseUrl}/test/staff?role=admin`, {
    headers: { Authorization: `Bearer ${makeToken({ role: 'admin' })}`, 'X-Role': 'admin' },
  });
  assert.equal(response.status, 403);
  assert.equal((await response.json()).error.code, 'FORBIDDEN');
});

test('database role changes apply to the next request using the same token', async (t) => {
  const { state } = setup(t);
  const token = makeToken({ role: 'admin' });
  let response = await get('/test/admin', token);
  assert.equal(response.status, 403);
  await response.json();
  state.user.role = 'admin';
  response = await get('/test/admin', token);
  assert.equal(response.status, 200);
  await response.json();
  state.user.role = 'patient';
  response = await get('/test/admin', token);
  assert.equal(response.status, 403);
  await response.json();
});

test('role middleware without authentication fails closed', async (t) => {
  setup(t);
  await assertUnauthorized(await get('/test/no-authentication'));
});

test('invalid or empty role configuration fails during route setup', () => {
  assert.throws(() => allowRoles(), /at least one/);
  assert.throws(() => allowRoles('owner'), /valid/);
  assert.throws(() => allowRoles('admin', 'owner'), /valid/);
});
