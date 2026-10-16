const { test } = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const User = require('../src/models/User');
const googleService = require('../src/services/google.service');
const {
  googleLogin: loginWithGoogle,
} = require('../src/services/google-login.service');

const identity = {
  googleSubject: 'google-123',
  name: 'Test Patient',
  email: 'patient@gmail.com',
};

function setup(t, state = {}) {
  const oldSecret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);

  t.after(() => {
    if (oldSecret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = oldSecret;
  });

  const verify = t.mock.method(
    googleService,
    'verifyGoogleToken',
    async () => identity
  );

  t.mock.method(User, 'init', async () => {});
  t.mock.method(User, 'findOne', async () => state.user ?? null);
  t.mock.method(User, 'exists', async () => state.conflict ?? null);

  const create = t.mock.method(User, 'create', async (data) => {
    const user = {
      ...data,
      _id: '507f1f77bcf86cd799439011',
    };

    if (state.race) {
      state.user = user;
      throw Object.assign(new Error('Duplicate'), { code: 11000 });
    }

    return user;
  });

  return { verify, create };
}

test('new Google account is a patient with a 15-minute JWT', async (t) => {
  const { create } = setup(t);

  const result = await loginWithGoogle({ idToken: 'fake-token' });
  const saved = create.mock.calls[0].arguments[0];

  assert.equal(saved.role, 'patient');
  assert.equal(saved.googleSubject, identity.googleSubject);
  assert.equal(saved.passwordHash, undefined);
  assert.ok(saved.emailVerifiedAt instanceof Date);

  const claims = jwt.verify(
    result.accessToken,
    Buffer.from('a'.repeat(64), 'hex'),
    {
      algorithms: ['HS256'],
      issuer: 'hospital-queue-api',
      audience: 'hospital-queue-clients',
    }
  );

  assert.equal(claims.sub, result.user.id);
  assert.equal(claims.exp - claims.iat, 900);
  assert.equal(result.expiresIn, 900);
  assert.deepEqual(
    Object.keys(result.user).sort(),
    ['email', 'id', 'name', 'role']
  );
});

test('existing Google user logs in without another account', async (t) => {
  const { create } = setup(t, {
    user: {
      _id: '507f1f77bcf86cd799439011',
      ...identity,
      role: 'doctor',
    },
  });

  const result = await loginWithGoogle({ idToken: 'fake-token' });

  assert.equal(create.mock.callCount(), 0);
  assert.equal(result.user.role, 'doctor');
});

test('same email does not automatically link accounts', async (t) => {
  const { create } = setup(t, { conflict: { _id: 'existing' } });

  await assert.rejects(
    loginWithGoogle({ idToken: 'fake-token' }),
    { status: 409, code: 'ACCOUNT_LINK_REQUIRED' }
  );

  assert.equal(create.mock.callCount(), 0);
});

test('client cannot request an admin role', async (t) => {
  const { verify, create } = setup(t);

  await assert.rejects(
    loginWithGoogle({ idToken: 'fake-token', role: 'admin' }),
    { status: 400, code: 'INVALID_INPUT' }
  );

  assert.equal(verify.mock.callCount(), 0);
  assert.equal(create.mock.callCount(), 0);
});

test('duplicate creation race finds the same Google identity', async (t) => {
  setup(t, { race: true });

  const result = await loginWithGoogle({ idToken: 'fake-token' });

  assert.equal(result.user.email, identity.email);
});

test('User schema supports both Google and password accounts', () => {
  const base = {
    name: 'Test Patient',
    email: 'patient@gmail.com',
    emailVerifiedAt: new Date(),
  };

  const googleUser = new User({
    ...base,
    googleSubject: 'google-123',
  });

  assert.equal(googleUser.validateSync(), undefined);

  const missingPassword = new User(base);
  assert.ok(missingPassword.validateSync().errors.passwordHash);

  const passwordUser = new User({
    ...base,
    passwordHash: '$2b$12$' + 'a'.repeat(53),
  });

  assert.equal(passwordUser.validateSync(), undefined);
});