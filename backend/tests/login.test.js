const { test } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../src/models/User');
const LoginChallenge = require('../src/models/LoginChallenge');
const otpService = require('../src/services/otp.service');
const emailService = require('../src/services/email.service');
const tokenService = require('../src/services/token.service');
const { requestLogin, verifyLogin } = require('../src/services/login.service');

const input = { email: 'patient@example.com', password: 'TestPassword123!' };
const challengeId = '507f1f77bcf86cd799439011';
const passwordHash = '$2b$12$' + 'a'.repeat(53);

function setup(t) {
  const oldSecret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (oldSecret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = oldSecret;
  });

  const session = {};
  const state = {
    matches: true,
    otpMatches: true,
    user: {
      _id: '507f1f77bcf86cd799439012',
      name: 'Test Patient',
      email: input.email,
      passwordHash,
      emailVerifiedAt: new Date(),
      role: 'patient',
    },
    challenge: {
      _id: challengeId,
      user: '507f1f77bcf86cd799439012',
      passwordHashSnapshot: passwordHash,
      otpHash: 'b'.repeat(64),
      attempts: 0,
      expiresAt: new Date(Date.now() + 300000),
    },
    existing: null,
  };

  t.mock.method(bcrypt, 'hash', async () => passwordHash);
  const compare = t.mock.method(bcrypt, 'compare', async () => state.matches);
  t.mock.method(User, 'findOne', () => ({ select: async () => state.user }));
  t.mock.method(User, 'findById', () => ({
    select: () => ({ session: async () => state.user }),
  }));
  t.mock.method(LoginChallenge, 'init', async () => {});
  t.mock.method(LoginChallenge, 'findOne', () => ({
    select: () => ({ lean: async () => state.existing }),
  }));
  t.mock.method(LoginChallenge, 'findById', () => ({
    select: () => ({ session: async () => state.challenge }),
  }));
  const transaction = t.mock.method(mongoose.connection, 'transaction',
    async (callback) => callback(session));
  t.mock.method(otpService, 'generateOtp', () => '001234');
  const hashOtp = t.mock.method(otpService, 'hashOtp', () => 'b'.repeat(64));
  const verifyOtp = t.mock.method(otpService, 'verifyOtp', () => state.otpMatches);

  const write = t.mock.method(LoginChallenge, 'findOneAndUpdate', async () => {
    if (state.writeError) throw state.writeError;
    return {};
  });
  const send = t.mock.method(emailService, 'sendLoginOtp', async () => {
    if (state.sendError) throw state.sendError;
  });
  const remove = t.mock.method(LoginChallenge, 'deleteOne', async () => ({}));
  const update = t.mock.method(LoginChallenge, 'updateOne', async () => {
    state.challenge.attempts += 1;
    return { modifiedCount: 1 };
  });
  const consume = t.mock.method(LoginChallenge, 'findOneAndDelete', async () => {
    if (state.consumeMiss) return null;
    const challenge = state.challenge;
    state.challenge = null;
    return challenge;
  });

  return {
    state, session, compare, hashOtp, verifyOtp, transaction,
    write, send, remove, update, consume,
  };
}

test('password login stores a bound five-minute challenge, sends OTP, and returns no JWT', async (t) => {
  const { state, write, send, hashOtp } = setup(t);
  const result = await requestLogin({ ...input, email: ' PATIENT@EXAMPLE.COM ' });
  const [filter, update, options] = write.mock.calls[0].arguments;
  const saved = update.$set;

  assert.equal(saved.user, state.user._id);
  assert.equal(saved.passwordHashSnapshot, passwordHash);
  assert.equal(saved.otpHash, 'b'.repeat(64));
  assert.equal(saved.attempts, 0);
  assert.equal(saved.expiresAt - saved.lastSentAt, 300000);
  assert.equal(saved.lastSentAt - filter.lastSentAt.$lte, 60000);
  assert.equal(options.upsert, true);
  assert.equal(options.runValidators, true);
  assert.deepEqual(hashOtp.mock.calls[0].arguments, ['001234', result.challengeId, 'login']);
  assert.deepEqual(send.mock.calls[0].arguments, [input.email, '001234']);
  assert.deepEqual(Object.keys(result).sort(), ['challengeId', 'message']);
});

test('unknown, wrong-password, unverified, and Google-only accounts share a generic error', async (t) => {
  const { state, compare, write, send } = setup(t);
  const user = state.user;
  for (const candidate of [null, { ...user, passwordHash: undefined },
    { ...user, emailVerifiedAt: undefined }, user]) {
    state.user = candidate;
    state.matches = false;
    await assert.rejects(requestLogin(input), {
      status: 401, code: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect.',
    });
  }
  assert.equal(compare.mock.callCount(), 4);
  assert.equal(write.mock.callCount(), 0);
  assert.equal(send.mock.callCount(), 0);
});

test('request uses bcrypt.compare with the actual stored hash', async (t) => {
  const realCompare = bcrypt.compare;
  const realHash = await bcrypt.hash(input.password, 4);
  const { state, compare, send } = setup(t);
  state.user.passwordHash = realHash;
  compare.mock.mockImplementation((password, hash) => realCompare(password, hash));
  await assert.rejects(requestLogin({ ...input, password: 'WrongPassword123!' }), {
    code: 'INVALID_CREDENTIALS',
  });
  assert.equal(send.mock.callCount(), 0);
  await requestLogin(input);
  assert.equal(send.mock.callCount(), 1);
});

test('request validation rejects missing, oversized, and privileged input before bcrypt', async (t) => {
  const { compare } = setup(t);
  for (const body of [null, [], {}, { ...input, email: 'invalid' },
    { ...input, password: 'a'.repeat(73) }, { ...input, password: 12345678 },
    { ...input, role: 'admin' }]) {
    await assert.rejects(requestLogin(body), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(compare.mock.callCount(), 0);
});

test('cooldown and database write failures never send an OTP', async (t) => {
  const { state, send } = setup(t);
  state.writeError = { code: 11000 };
  await assert.rejects(requestLogin(input), { status: 429, code: 'LOGIN_COOLDOWN' });
  state.writeError = new Error('Database unavailable');
  await assert.rejects(requestLogin(input), /Database unavailable/);
  assert.equal(send.mock.callCount(), 0);
});

test('email failure cleans only the issued challenge version', async (t) => {
  const { state, write, remove } = setup(t);
  state.sendError = new Error('Private SMTP diagnostic');
  await assert.rejects(requestLogin(input), { status: 503, code: 'EMAIL_UNAVAILABLE' });
  const filter = remove.mock.calls[0].arguments[0];
  assert.equal(filter._id.toString(), write.mock.calls[0].arguments[0]._id.toString());
  assert.equal(filter.otpHash, 'b'.repeat(64));
});

test('existing challenge ID is reused under an atomic cooldown filter', async (t) => {
  const { state, write } = setup(t);
  state.existing = { _id: new mongoose.Types.ObjectId(challengeId) };
  const result = await requestLogin(input);
  assert.equal(result.challengeId, challengeId);
  assert.equal(write.mock.calls[0].arguments[0]._id.toString(), challengeId);
});

test('verification issues a signed 15-minute JWT after consuming the challenge in the session', async (t) => {
  const { state, session, transaction, consume, verifyOtp } = setup(t);
  const result = await verifyLogin({ challengeId, otp: '001234' });
  const claims = jwt.verify(result.accessToken, Buffer.from('a'.repeat(64), 'hex'), {
    algorithms: ['HS256'], issuer: 'hospital-queue-api', audience: 'hospital-queue-clients',
  });
  assert.equal(claims.sub, state.user._id);
  assert.equal(claims.exp - claims.iat, 900);
  assert.equal(result.expiresIn, 900);
  assert.equal(result.tokenType, 'Bearer');
  assert.deepEqual(Object.keys(result.user).sort(), ['email', 'id', 'name', 'role']);
  assert.equal(consume.mock.calls[0].arguments[1].session, session);
  assert.deepEqual(verifyOtp.mock.calls[0].arguments, ['001234', challengeId, 'b'.repeat(64), 'login']);
  assert.equal(transaction.mock.calls[0].arguments[1].writeConcern.w, 'majority');
  await assert.rejects(verifyLogin({ challengeId, otp: '001234' }), {
    code: 'INVALID_OR_EXPIRED_OTP',
  });
});

test('fifth wrong OTP persists the lockout and correct OTP then fails', async (t) => {
  const { state, update, consume } = setup(t);
  state.challenge.attempts = 4;
  state.otpMatches = false;
  await assert.rejects(verifyLogin({ challengeId, otp: '999999' }), {
    code: 'INVALID_OR_EXPIRED_OTP',
  });
  assert.equal(state.challenge.attempts, 5);
  assert.deepEqual(update.mock.calls[0].arguments[1], { $inc: { attempts: 1 } });
  state.otpMatches = true;
  await assert.rejects(verifyLogin({ challengeId, otp: '001234' }), {
    code: 'INVALID_OR_EXPIRED_OTP',
  });
  assert.equal(consume.mock.callCount(), 0);
});

test('expired, missing and exhausted login challenges cannot issue tokens', async (t) => {
  const { state, verifyOtp, consume } = setup(t);
  const valid = state.challenge;
  for (const challenge of [null, { ...valid, expiresAt: new Date(Date.now() - 1) },
    { ...valid, attempts: 5 }]) {
    state.challenge = challenge;
    await assert.rejects(verifyLogin({ challengeId, otp: '001234' }), {
      code: 'INVALID_OR_EXPIRED_OTP',
    });
  }
  assert.equal(verifyOtp.mock.callCount(), 0);
  assert.equal(consume.mock.callCount(), 0);
});

test('deleted, unverified or password-changed users cannot finish login', async (t) => {
  const { state } = setup(t);
  const user = state.user;
  const challenge = state.challenge;
  for (const candidate of [null, { ...user, emailVerifiedAt: undefined },
    { ...user, passwordHash: undefined }, { ...user, passwordHash: '$2b$12$' + 'c'.repeat(53) }]) {
    state.user = candidate;
    state.challenge = { ...challenge };
    await assert.rejects(verifyLogin({ challengeId, otp: '001234' }), {
      code: 'INVALID_OR_EXPIRED_OTP',
    });
  }
});

test('failed atomic consumption cannot complete login', async (t) => {
  const { state } = setup(t);
  state.consumeMiss = true;
  await assert.rejects(verifyLogin({ challengeId, otp: '001234' }), {
    code: 'INVALID_OR_EXPIRED_OTP',
  });
});

test('invalid verification input is rejected without opening a transaction', async (t) => {
  const { transaction } = setup(t);
  for (const body of [{}, [], null, { challengeId: 'bad', otp: '123456' },
    { challengeId, otp: 123456 }, { challengeId, otp: '123' },
    { challengeId, otp: '001234', role: 'admin' }]) {
    await assert.rejects(verifyLogin(body), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(transaction.mock.callCount(), 0);
});

test('missing JWT configuration fails before consuming a challenge', async (t) => {
  const { transaction, consume } = setup(t);
  delete process.env.JWT_SECRET;
  await assert.rejects(verifyLogin({ challengeId, otp: '001234' }), /JWT_SECRET/);
  assert.equal(transaction.mock.callCount(), 0);
  assert.equal(consume.mock.callCount(), 0);
});

test('JWT signing failure propagates out of the transaction callback', async (t) => {
  const { transaction } = setup(t);
  t.mock.method(tokenService, 'issueAccessToken', () => { throw new Error('Signing failed'); });
  await assert.rejects(verifyLogin({ challengeId, otp: '001234' }), /Signing failed/);
  assert.equal(transaction.mock.callCount(), 1);
});

test('LoginChallenge validates hashes and protects them from default selection', async () => {
  const base = {
    user: '507f1f77bcf86cd799439012', passwordHashSnapshot: passwordHash,
    otpHash: 'b'.repeat(64), expiresAt: new Date(Date.now() + 300000), lastSentAt: new Date(),
  };
  const valid = new LoginChallenge(base);
  await valid.validate();
  assert.equal(valid.attempts, 0);
  for (const change of [{ otpHash: '123456' }, { passwordHashSnapshot: 'plaintext' },
    { attempts: 6 }, { attempts: 1.5 }]) {
    await assert.rejects(new LoginChallenge({ ...base, ...change }).validate());
  }
  assert.equal(LoginChallenge.schema.path('otpHash').options.select, false);
  assert.equal(LoginChallenge.schema.path('passwordHashSnapshot').options.select, false);
});
