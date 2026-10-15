const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  validateRegistration,
} = require('../src/validators/auth.validator');

function validData() {
  return {
    name: 'Test Patient',
    email: 'patient@example.com',
    password: 'TestPassword123!',
  };
}

test('valid input is normalized without changing password', () => {
  const result = validateRegistration({
    name: '  Test Patient  ',
    email: '  PATIENT@EXAMPLE.COM  ',
    password: ' Password123! ',
  });

  assert.deepEqual(result, {
    data: {
      name: 'Test Patient',
      email: 'patient@example.com',
      password: ' Password123! ',
    },
  });
});

test('invalid bodies and missing fields are rejected', () => {
  for (const body of [undefined, null, [], 'text', 123]) {
    assert.ok(validateRegistration(body).error);
  }

  for (const field of ['name', 'email', 'password']) {
    const missing = validData();
    delete missing[field];

    assert.ok(validateRegistration(missing).error);

    const wrongType = validData();
    wrongType[field] = 123;

    assert.ok(validateRegistration(wrongType).error);
  }
});

test('privileged role and unexpected fields are rejected', () => {
  assert.ok(
    validateRegistration({ ...validData(), role: 'admin' }).error
  );

  assert.ok(
    validateRegistration({ ...validData(), extra: 'value' }).error
  );
});

test('invalid names and emails are rejected', () => {
  for (const name of [' ', 'A', 'a'.repeat(101), 'Test\nPatient']) {
    assert.ok(validateRegistration({ ...validData(), name }).error);
  }

  for (const email of ['', 'invalid-email', 'a'.repeat(255)]) {
    assert.ok(validateRegistration({ ...validData(), email }).error);
  }
});

test('password length and byte limits are enforced', () => {
  for (const password of ['', 'short', '        ', 'a'.repeat(73)]) {
    assert.ok(
      validateRegistration({ ...validData(), password }).error
    );
  }

  assert.ok(
    validateRegistration({
      ...validData(),
      password: 'a'.repeat(72),
    }).data
  );

  // Each emoji uses four UTF-8 bytes.
  assert.ok(
    validateRegistration({
      ...validData(),
      password: '😀'.repeat(18),
    }).data
  );

  assert.ok(
    validateRegistration({
      ...validData(),
      password: '😀'.repeat(19),
    }).error
  );
});