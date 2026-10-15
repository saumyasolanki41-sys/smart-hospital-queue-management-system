const { test } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const User = require('../src/models/User');
const Pending = require('../src/models/PendingRegistration');
const otpService = require('../src/services/otp.service');
const emailService = require('../src/services/email.service');
const {
  requestRegistration,
} = require('../src/services/registration.service');

const input = {
  name: 'Test Patient',
  email: 'patient@example.com',
  password: 'TestPassword123!',
};

function setup(t, state = {}) {
  t.mock.method(User, 'init', async () => {});
  t.mock.method(Pending, 'init', async () => {});
  t.mock.method(User, 'exists', async () => state.user ?? null);

  t.mock.method(Pending, 'findOne', () => ({
    select: () => ({
      lean: async () => null,
    }),
  }));

  const hash = t.mock.method(
    bcrypt,
    'hash',
    async () => '$2b$12$' + 'a'.repeat(53)
  );

  t.mock.method(otpService, 'generateOtp', () => '001234');
  t.mock.method(otpService, 'hashOtp', () => 'b'.repeat(64));

  const write = t.mock.method(
    Pending,
    'findOneAndUpdate',
    async () => {
      if (state.writeError) throw state.writeError;
      return {};
    }
  );

  const send = t.mock.method(
    emailService,
    'sendRegistrationOtp',
    async () => {
      if (state.sendError) throw state.sendError;
    }
  );

  const remove = t.mock.method(Pending, 'deleteOne', async () => ({}));

  return { hash, write, send, remove };
}

test('invalid input fails before database or hashing', async (t) => {
  const { hash, write, send } = setup(t);

  await assert.rejects(requestRegistration({}), {
    status: 400,
    code: 'VALIDATION_ERROR',
  });

  assert.equal(hash.mock.callCount(), 0);
  assert.equal(write.mock.callCount(), 0);
  assert.equal(send.mock.callCount(), 0);
});

test('registration stores hashes and sends OTP', async (t) => {
  const { hash, write, send } = setup(t);

  const result = await requestRegistration(input);

  const [filter, update, options] = write.mock.calls[0].arguments;
  const saved = update.$set;

  assert.deepEqual(hash.mock.calls[0].arguments, [input.password, 12]);
  assert.notEqual(saved.passwordHash, input.password);
  assert.equal(saved.otpHash, 'b'.repeat(64));
  assert.equal(saved.attempts, 0);

  assert.equal(
    saved.expiresAt.getTime() - saved.lastSentAt.getTime(),
    5 * 60 * 1000
  );

  assert.equal(
    saved.lastSentAt.getTime() - filter.lastSentAt.$lte.getTime(),
    60 * 1000
  );

  assert.equal(options.upsert, true);
  assert.equal(options.runValidators, true);

  assert.deepEqual(send.mock.calls[0].arguments, [
    input.email,
    '001234',
  ]);

  // Public response contains only the generic message.
  assert.deepEqual(Object.keys(result), ['message']);
});

test('existing account does not create or email a challenge', async (t) => {
  const { write, send } = setup(t, { user: { _id: 'existing-user' } });

  const result = await requestRegistration(input);

  assert.ok(result.message);
  assert.equal(write.mock.callCount(), 0);
  assert.equal(send.mock.callCount(), 0);
});

test('cooldown blocks sending and mail failure cleans its challenge', async (t) => {
  const state = { writeError: { code: 11000 } };
  const { write, send, remove } = setup(t, state);

  await assert.rejects(requestRegistration(input), {
    status: 429,
    code: 'REGISTRATION_COOLDOWN',
  });

  assert.equal(send.mock.callCount(), 0);

  state.writeError = undefined;
  state.sendError = new Error('Mail unavailable');

  await assert.rejects(requestRegistration(input), {
    status: 503,
    code: 'EMAIL_UNAVAILABLE',
  });

  const latestWrite = write.mock.calls.at(-1).arguments;
  const cleanup = remove.mock.calls[0].arguments[0];

  assert.equal(cleanup._id.toString(), latestWrite[0]._id.toString());
  assert.equal(cleanup.otpHash, latestWrite[1].$set.otpHash);
  assert.equal(remove.mock.callCount(), 1);
});