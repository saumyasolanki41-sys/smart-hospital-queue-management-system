const { test } = require('node:test');
const assert = require('node:assert/strict');
const { OAuth2Client } = require('google-auth-library');
const { verifyGoogleToken } = require('../src/services/google.service');

function setup(t, payload) {
  const oldClientId = process.env.GOOGLE_WEB_CLIENT_ID;
  process.env.GOOGLE_WEB_CLIENT_ID = 'test.apps.googleusercontent.com';

  t.after(() => {
    if (oldClientId === undefined) {
      delete process.env.GOOGLE_WEB_CLIENT_ID;
    } else {
      process.env.GOOGLE_WEB_CLIENT_ID = oldClientId;
    }
  });

  return t.mock.method(
    OAuth2Client.prototype,
    'verifyIdToken',
    async () => ({ getPayload: () => payload })
  );
}

function validPayload() {
  return {
    sub: 'google-user-123',
    email: 'patient@gmail.com',
    email_verified: true,
    name: 'Test Patient',
  };
}

test('valid identity is returned with the configured audience', async (t) => {
  const verify = setup(t, validPayload());

  const identity = await verifyGoogleToken('fake-test-token');

  assert.deepEqual(identity, {
    googleSubject: 'google-user-123',
    email: 'patient@gmail.com',
    name: 'Test Patient',
  });

  assert.deepEqual(verify.mock.calls[0].arguments[0], {
    idToken: 'fake-test-token',
    audience: 'test.apps.googleusercontent.com',
  });
});

test('missing token is rejected before Google verification', async (t) => {
  const verify = setup(t, validPayload());

  for (const token of [undefined, '', ' ', 123]) {
    await assert.rejects(verifyGoogleToken(token), {
      status: 400,
      code: 'INVALID_INPUT',
    });
  }

  assert.equal(verify.mock.callCount(), 0);
});

test('rejected Google token returns a safe error', async (t) => {
  setup(t, validPayload()).mock.mockImplementation(async () => {
    throw new Error('Private verification diagnostic');
  });

  await assert.rejects(verifyGoogleToken('invalid-token'), {
    status: 401,
    code: 'INVALID_GOOGLE_TOKEN',
    message: 'Google sign-in could not be verified.',
  });
});

test('unverified email is rejected', async (t) => {
  setup(t, { ...validPayload(), email_verified: false });

  await assert.rejects(verifyGoogleToken('fake-test-token'), {
    status: 401,
    code: 'INVALID_GOOGLE_TOKEN',
  });
});

test('third-party email needs additional verification', async (t) => {
  setup(t, { ...validPayload(), email: 'patient@example.com' });

  await assert.rejects(verifyGoogleToken('fake-test-token'), {
    status: 403,
    code: 'EMAIL_VERIFICATION_REQUIRED',
  });
});