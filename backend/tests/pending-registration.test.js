const { test } = require('node:test');
const assert = require('node:assert/strict');
const PendingRegistration = require('../src/models/PendingRegistration');

function validData() {
  return {
    name: 'Test Patient',
    email: 'patient@example.com',
    // Sirf schema-test fixtures; real password/OTP hashes nahi hain.
    passwordHash: '$2b$12$' + 'a'.repeat(53),
    otpHash: 'a'.repeat(64),
    expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    lastSentAt: new Date(),
  };
}

test('valid registration data passes validation', () => {
  const pending = new PendingRegistration(validData());

  assert.equal(pending.validateSync(), undefined);
  assert.equal(pending.attempts, 0);
});

test('name and email are normalized', () => {
  const pending = new PendingRegistration({
    ...validData(),
    name: '  Test Patient  ',
    email: '  PATIENT@EXAMPLE.COM  ',
  });

  assert.equal(pending.name, 'Test Patient');
  assert.equal(pending.email, 'patient@example.com');
});

test('missing required fields are rejected', () => {
  const error = new PendingRegistration({}).validateSync();

  for (const field of [
    'name',
    'email',
    'passwordHash',
    'otpHash',
    'expiresAt',
    'lastSentAt',
  ]) {
    assert.ok(error.errors[field], `${field} should be required`);
  }
});

test('invalid email and plain-text credentials are rejected', () => {
  const pending = new PendingRegistration({
    ...validData(),
    email: 'invalid-email',
    passwordHash: 'plain-password',
    otpHash: '123456',
  });

  const error = pending.validateSync();

  assert.ok(error.errors.email);
  assert.ok(error.errors.passwordHash);
  assert.ok(error.errors.otpHash);
});

test('invalid attempt counts are rejected', () => {
  for (const attempts of [-1, 6, 1.5]) {
    const pending = new PendingRegistration({
      ...validData(),
      attempts,
    });

    assert.ok(pending.validateSync().errors.attempts);
  }
});