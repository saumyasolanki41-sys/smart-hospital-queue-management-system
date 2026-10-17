const { test } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('../src/models/User');
const PasswordReset = require('../src/models/PasswordReset');
const LoginChallenge = require('../src/models/LoginChallenge');
const otpService = require('../src/services/otp.service');
const emailService = require('../src/services/email.service');
const app = require('../src/app');
const { forgotPassword, resetPassword } = require('../src/services/password-reset.service');

const input = { email: 'patient@example.com', otp: '001234', newPassword: 'NewPassword123!' };
const hash = '$2b$12$' + 'a'.repeat(53);

test('reset OTP hashes cannot be used for login or registration', (t) => {
  const oldSecret = process.env.OTP_HASH_SECRET;
  process.env.OTP_HASH_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (oldSecret === undefined) delete process.env.OTP_HASH_SECRET;
    else process.env.OTP_HASH_SECRET = oldSecret;
  });
  const id = '507f1f77bcf86cd799439012';
  const resetHash = otpService.hashOtp(input.otp, id, 'password-reset');
  assert.equal(otpService.verifyOtp(input.otp, id, resetHash, 'password-reset'), true);
  assert.equal(otpService.verifyOtp(input.otp, id, resetHash, 'login'), false);
  assert.equal(otpService.verifyOtp(input.otp, id, resetHash), false);
});

test('password reset routes return safe HTTP responses and reject OTP replay', async (t) => {
  setup(t);
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}/api/auth`;
  async function post(path, body) {
    return fetch(base + path, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
    });
  }
  const invalid = await post('/forgot-password', {});
  assert.equal(invalid.status, 400);
  const requested = await post('/forgot-password', { email: input.email });
  assert.equal(requested.status, 202);
  assert.equal(requested.headers.get('cache-control'), 'no-store');
  const reset = await post('/reset-password', input);
  assert.equal(reset.status, 200);
  assert.deepEqual(Object.keys((await reset.json()).data), ['message']);
  const replay = await post('/reset-password', input);
  assert.equal(replay.status, 400);
  assert.equal((await replay.json()).error.code, 'INVALID_OR_EXPIRED_OTP');
});

function setup(t) {
  const state = {
    user: { _id: '507f1f77bcf86cd799439011', passwordHash: hash, emailVerifiedAt: new Date() },
    challenge: {
      _id: '507f1f77bcf86cd799439012', passwordHashSnapshot: hash,
      otpHash: 'b'.repeat(64), attempts: 0, expiresAt: new Date(Date.now() + 300000),
    },
    otpCorrect: true,
  };
  const session = {};
  t.mock.method(User, 'findOne', () => ({ select: () => ({
    then: (resolve) => Promise.resolve(state.user).then(resolve),
    session: async () => state.user,
  }) }));
  t.mock.method(PasswordReset, 'init', async () => {});
  t.mock.method(LoginChallenge, 'init', async () => {});
  t.mock.method(PasswordReset, 'findOne', () => ({
    then: (resolve) => Promise.resolve(state.challenge).then(resolve),
    select: () => ({ session: async () => state.challenge }),
  }));
  const transaction = t.mock.method(mongoose.connection, 'transaction', async (callback) => callback(session));
  t.mock.method(otpService, 'generateOtp', () => '001234');
  const hashOtp = t.mock.method(otpService, 'hashOtp', () => 'b'.repeat(64));
  const verify = t.mock.method(otpService, 'verifyOtp', () => state.otpCorrect);
  const write = t.mock.method(PasswordReset, 'findOneAndUpdate', async () => {
    if (state.writeError) throw state.writeError;
    return {};
  });
  const send = t.mock.method(emailService, 'sendPasswordResetOtp', async () => {
    if (state.mailError) throw state.mailError;
  });
  const cleanup = t.mock.method(PasswordReset, 'deleteOne', async () => ({}));
  const attempts = t.mock.method(PasswordReset, 'updateOne', async () => {
    state.challenge.attempts += 1;
  });
  const consume = t.mock.method(PasswordReset, 'findOneAndDelete', async () => {
    if (state.consumeMiss) return null;
    const challenge = state.challenge;
    state.challenge = null;
    return challenge;
  });
  const updateUser = t.mock.method(User, 'updateOne', async () => {
    if (state.databaseError) throw state.databaseError;
    return { modifiedCount: state.updateMiss ? 0 : 1 };
  });
  const removeLogins = t.mock.method(LoginChallenge, 'deleteMany', async () => ({}));
  const hashPassword = t.mock.method(bcrypt, 'hash', async () => '$2b$12$' + 'c'.repeat(53));
  return { state, session, transaction, hashOtp, verify, write, send, cleanup,
    attempts, consume, updateUser, removeLogins, hashPassword };
}

test('forgot password uses a purpose-bound hash, five-minute expiry and atomic cooldown', async (t) => {
  const { write, hashOtp, send } = setup(t);
  const result = await forgotPassword({ email: ' PATIENT@EXAMPLE.COM ' });
  assert.deepEqual(Object.keys(result), ['message']);
  const [filter, update, options] = write.mock.calls[0].arguments;
  assert.equal(update.$set.expiresAt - update.$set.lastSentAt, 300000);
  assert.equal(update.$set.lastSentAt - filter.lastSentAt.$lte, 60000);
  assert.equal(update.$set.attempts, 0);
  assert.equal(options.upsert, true);
  assert.equal(hashOtp.mock.calls[0].arguments[2], 'password-reset');
  assert.deepEqual(send.mock.calls[0].arguments, ['patient@example.com', '001234']);
});

test('unknown, Google-only, unverified accounts and cooldown share the accepted response', async (t) => {
  const { state, send } = setup(t);
  state.writeError = { code: 11000 };
  const expected = await forgotPassword({ email: input.email });
  for (const user of [null, { ...state.user, passwordHash: undefined },
    { ...state.user, emailVerifiedAt: undefined }]) {
    state.user = user;
    assert.deepEqual(await forgotPassword({ email: input.email }), expected);
  }
  assert.equal(send.mock.callCount(), 0);
});

test('mail failure deletes only the failed challenge version', async (t) => {
  const { state, cleanup, write } = setup(t);
  state.mailError = new Error('Private SMTP details');
  await assert.rejects(forgotPassword({ email: input.email }), { code: 'EMAIL_UNAVAILABLE' });
  assert.deepEqual(cleanup.mock.calls[0].arguments[0], {
    _id: write.mock.calls[0].arguments[0]._id, otpHash: 'b'.repeat(64),
  });
});

test('reset atomically consumes OTP, hashes password, revokes tokens and removes login challenges', async (t) => {
  const { session, consume, updateUser, removeLogins, hashPassword, verify } = setup(t);
  const result = await resetPassword(input);
  assert.match(result.message, /successful/);
  assert.deepEqual(hashPassword.mock.calls[0].arguments, [input.newPassword, 12]);
  assert.equal(verify.mock.calls[0].arguments[3], 'password-reset');
  assert.equal(consume.mock.calls[0].arguments[1].session, session);
  const [filter, update, options] = updateUser.mock.calls[0].arguments;
  assert.equal(filter.passwordHash, hash);
  assert.equal(update.$set.passwordHash, '$2b$12$' + 'c'.repeat(53));
  assert.deepEqual(update.$inc, { tokenVersion: 1 });
  assert.equal(options.session, session);
  assert.equal(removeLogins.mock.calls[0].arguments[1].session, session);
  await assert.rejects(resetPassword(input), { code: 'INVALID_OR_EXPIRED_OTP' });
  assert.equal(updateUser.mock.callCount(), 1);
});

test('five wrong OTPs persist lockout and reject a later correct OTP', async (t) => {
  const { state, attempts, updateUser } = setup(t);
  state.otpCorrect = false;
  for (let attempt = 0; attempt < 5; attempt += 1) {
    await assert.rejects(resetPassword(input), { code: 'INVALID_OR_EXPIRED_OTP' });
  }
  state.otpCorrect = true;
  await assert.rejects(resetPassword(input), { code: 'INVALID_OR_EXPIRED_OTP' });
  assert.equal(attempts.mock.callCount(), 5);
  assert.equal(updateUser.mock.callCount(), 0);
});

test('missing, expired, stale-password and exhausted challenges cannot reset passwords', async (t) => {
  const { state, updateUser } = setup(t);
  const valid = state.challenge;
  for (const challenge of [null, { ...valid, expiresAt: new Date(0) },
    { ...valid, passwordHashSnapshot: 'old hash' }, { ...valid, attempts: 5 }]) {
    state.challenge = challenge;
    await assert.rejects(resetPassword(input), { code: 'INVALID_OR_EXPIRED_OTP' });
  }
  assert.equal(updateUser.mock.callCount(), 0);
});

test('failed consumption and concurrent password change cannot report success', async (t) => {
  const { state, updateUser, removeLogins } = setup(t);
  state.consumeMiss = true;
  await assert.rejects(resetPassword(input), { code: 'INVALID_OR_EXPIRED_OTP' });
  assert.equal(updateUser.mock.callCount(), 0);
  state.consumeMiss = false;
  state.updateMiss = true;
  await assert.rejects(resetPassword(input), { code: 'INVALID_OR_EXPIRED_OTP' });
  assert.equal(removeLogins.mock.callCount(), 0);
});

test('database failure propagates out of the transaction for rollback', async (t) => {
  const { state, removeLogins } = setup(t);
  state.databaseError = new Error('Database write failed');
  await assert.rejects(resetPassword(input), /Database write failed/);
  assert.equal(removeLogins.mock.callCount(), 0);
});

test('validation rejects unexpected fields, non-string OTP and invalid passwords before writes', async (t) => {
  const { transaction, write } = setup(t);
  for (const body of [null, [], {}, { email: 'bad' }, { email: input.email, role: 'admin' }]) {
    await assert.rejects(forgotPassword(body), { code: 'VALIDATION_ERROR' });
  }
  for (const body of [{ ...input, otp: 123456 }, { ...input, newPassword: 'short' },
    { ...input, newPassword: 'a'.repeat(73) }, { ...input, role: 'admin' }]) {
    await assert.rejects(resetPassword(body), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(transaction.mock.callCount(), 0);
  assert.equal(write.mock.callCount(), 0);
});
