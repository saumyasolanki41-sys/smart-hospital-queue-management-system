const { test } = require('node:test');
const assert = require('node:assert/strict');
const nodemailer = require('nodemailer');
const { sendRegistrationOtp, sendLoginOtp } = require('../src/services/email.service');

function setupMail(t, sendMail) {
  const oldUser = process.env.SMTP_USER;
  const oldPass = process.env.SMTP_PASS;

  process.env.SMTP_USER = 'sender@example.com';
  process.env.SMTP_PASS = 'fake-test-password';

  t.after(() => {
    if (oldUser === undefined) delete process.env.SMTP_USER;
    else process.env.SMTP_USER = oldUser;

    if (oldPass === undefined) delete process.env.SMTP_PASS;
    else process.env.SMTP_PASS = oldPass;
  });

  const transport = {
    sendMail: t.mock.fn(sendMail),
    close: t.mock.fn(),
  };

  const createTransport = t.mock.method(
    nodemailer,
    'createTransport',
    () => transport
  );

  return { transport, createTransport };
}

test('invalid email or OTP does not create a mail connection', async (t) => {
  const { createTransport } = setupMail(t, async () => ({}));

  await assert.rejects(
    sendRegistrationOtp('invalid', '123456'),
    /Valid email/
  );

  await assert.rejects(
    sendRegistrationOtp('patient@example.com', '123'),
    /six-digit/
  );

  assert.equal(createTransport.mock.callCount(), 0);
});

test('valid OTP email is sent and connection is closed', async (t) => {
  const { transport } = setupMail(t, async () => ({
    accepted: ['patient@example.com'],
  }));

  await sendRegistrationOtp('patient@example.com', '001234');

  const message = transport.sendMail.mock.calls[0].arguments[0];

  assert.equal(message.to, 'patient@example.com');
  assert.equal(message.from.address, 'sender@example.com');
  assert.ok(message.text.includes('001234'));
  assert.equal(transport.sendMail.mock.callCount(), 1);
  assert.equal(transport.close.mock.callCount(), 1);
});

test('mail failures return a safe error and close connection', async (t) => {
  let shouldThrow = false;

  const { transport } = setupMail(t, async () => {
    if (shouldThrow) {
      throw new Error('Private SMTP diagnostic');
    }

    return { accepted: [] };
  });

  
  await assert.rejects(
    sendRegistrationOtp('patient@example.com', '123456'),
    { message: 'Registration email could not be sent.' }
  );

  
  shouldThrow = true;

  await assert.rejects(
    sendRegistrationOtp('patient@example.com', '123456'),
    { message: 'Registration email could not be sent.' }
  );

  assert.equal(transport.close.mock.callCount(), 2);
});

test('login email uses the login subject and preserves leading OTP zeroes', async (t) => {
  const { transport } = setupMail(t, async () => ({ accepted: ['patient@example.com'] }));
  await sendLoginOtp('patient@example.com', '001234');
  const message = transport.sendMail.mock.calls[0].arguments[0];
  assert.equal(message.subject, 'Your Hospital Queue login OTP');
  assert.ok(message.text.includes('Your login OTP is: 001234'));
  assert.equal(transport.close.mock.callCount(), 1);
});
