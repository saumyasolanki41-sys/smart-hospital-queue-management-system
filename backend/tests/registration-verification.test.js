const { test } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Pending = require('../src/models/PendingRegistration');
const otpService = require('../src/services/otp.service');
const {
  verifyRegistration,
} = require('../src/services/registration-verification.service');

const input = {
  email: 'patient@example.com',
  otp: '001234',
};

function setup(t) {
  const session = {};
  const state = {
    matches: true,
    conflict: false,
    pending: {
      _id: '507f1f77bcf86cd799439011',
      name: 'Test Patient',
      email: input.email,
      passwordHash: '$2b$12$' + 'a'.repeat(53),
      otpHash: 'b'.repeat(64),
      attempts: 0,
      expiresAt: new Date(Date.now() + 300000),
    },
  };

  t.mock.method(User, 'init', async () => {});
  t.mock.method(Pending, 'init', async () => {});

  const transaction = t.mock.method(
    mongoose.connection,
    'transaction',
    async (callback) => callback(session)
  );

  t.mock.method(Pending, 'findOne', () => ({
    select: () => ({
      session: async () => state.pending,
    }),
  }));

  t.mock.method(otpService, 'verifyOtp', () => state.matches);

  const update = t.mock.method(
    Pending,
    'updateOne',
    async () => ({ modifiedCount: 1 })
  );

  const consume = t.mock.method(
    Pending,
    'findOneAndDelete',
    async () => {
      const pending = state.pending;
      state.pending = null;
      return pending;
    }
  );

  t.mock.method(User, 'exists', () => ({
    session: async () => state.conflict,
  }));

  const create = t.mock.method(User, 'create', async ([data]) => [{
    ...data,
    _id: '507f1f77bcf86cd799439012',
  }]);

  return { state, session, transaction, update, consume, create };
}

test('invalid input is rejected before transaction', async (t) => {
  const { transaction } = setup(t);

  for (const body of [
    {},
    { ...input, otp: 123456 },
    { ...input, role: 'admin' },
    { ...input, email: 'invalid' },
  ]) {
    await assert.rejects(verifyRegistration(body), {
      code: 'VALIDATION_ERROR',
    });
  }

  assert.equal(transaction.mock.callCount(), 0);
});

test('valid OTP creates patient using the stored password hash', async (t) => {
  const { state, session, create, consume } = setup(t);
  const storedHash = state.pending.passwordHash;

  const result = await verifyRegistration(input);

  const [documents, options] = create.mock.calls[0].arguments;

  assert.equal(documents[0].role, 'patient');
  assert.equal(documents[0].passwordHash, storedHash);
  assert.equal(options.session, session);
  assert.equal(consume.mock.calls[0].arguments[1].session, session);

  assert.deepEqual(Object.keys(result.user).sort(), [
    'email', 'id', 'name', 'role',
  ]);

  await assert.rejects(verifyRegistration(input), {
    code: 'INVALID_OR_EXPIRED_OTP',
  });

  assert.equal(create.mock.callCount(), 1);
});

test('wrong OTP increments attempts without creating a user', async (t) => {
  const { state, update, consume, create } = setup(t);
  state.matches = false;

  await assert.rejects(verifyRegistration(input), {
    code: 'INVALID_OR_EXPIRED_OTP',
  });

  assert.deepEqual(
    update.mock.calls[0].arguments[1],
    { $inc: { attempts: 1 } }
  );

  assert.equal(consume.mock.callCount(), 0);
  assert.equal(create.mock.callCount(), 0);
});

test('missing, expired and exhausted challenges are rejected', async (t) => {
  const { state, update, create } = setup(t);
  const valid = state.pending;

  for (const pending of [
    null,
    { ...valid, expiresAt: new Date(Date.now() - 1000) },
    { ...valid, attempts: 5 },
  ]) {
    state.pending = pending;

    await assert.rejects(verifyRegistration(input), {
      code: 'INVALID_OR_EXPIRED_OTP',
    });
  }

  assert.equal(update.mock.callCount(), 0);
  assert.equal(create.mock.callCount(), 0);
});

test('existing account is not overwritten', async (t) => {
  const { state, create } = setup(t);
  state.conflict = true;

  await assert.rejects(verifyRegistration(input), {
    code: 'ACCOUNT_EXISTS',
  });

  assert.equal(create.mock.callCount(), 0);
});