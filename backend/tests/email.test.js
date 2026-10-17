const { test } = require('node:test');
const assert = require('node:assert/strict');
const nodemailer = require('nodemailer');
const { sendRegistrationOtp, sendLoginOtp, sendPasswordResetOtp } = require('../src/services/email.service');

test('reset email clearly identifies password reset and preserves OTP zeroes', async (t) => {
  const { transport } = setupMail(t, async () => ({ accepted: ['patient@example.com'] }));
  await sendPasswordResetOtp('patient@example.com', '001234');
  const message = transport.sendMail.mock.calls[0].arguments[0];
  assert.equal(message.subject, 'Reset your Hospital Queue password');
  assert.ok(message.text.includes('Your password reset OTP is: 001234'));
  assert.equal(transport.close.mock.callCount(), 1);
});

function setupMail(t, sendMail) {
  const oldUser = process.env.SMTP_USER;
  const oldPass = process.env.SMTP_PASS;
  const oldProvider = process.env.EMAIL_PROVIDER;

  process.env.SMTP_USER = 'sender@example.com';
  process.env.SMTP_PASS = 'fake-test-password';
  process.env.EMAIL_PROVIDER = 'smtp';

  t.after(() => {
    if (oldUser === undefined) delete process.env.SMTP_USER;
    else process.env.SMTP_USER = oldUser;

    if (oldPass === undefined) delete process.env.SMTP_PASS;
    else process.env.SMTP_PASS = oldPass;

    if (oldProvider === undefined) delete process.env.EMAIL_PROVIDER;
    else process.env.EMAIL_PROVIDER = oldProvider;
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

function setupBrevo(t) {
  const keys = ['EMAIL_PROVIDER', 'BREVO_API_KEY', 'BREVO_SENDER_EMAIL'];
  const original = {};
  for (const key of keys) original[key] = process.env[key];
  process.env.EMAIL_PROVIDER = 'brevo';
  process.env.BREVO_API_KEY = 'fake-api-key';
  process.env.BREVO_SENDER_EMAIL = 'sender@example.com';
  t.after(() => {
    for (const key of keys) {
      if (original[key] === undefined) delete process.env[key];
      else process.env[key] = original[key];
    }
  });
  const smtp = t.mock.method(nodemailer, 'createTransport', () => {
    throw new Error('SMTP must not be used.');
  });
  const request = t.mock.method(globalThis, 'fetch', async () =>
    new Response(JSON.stringify({ messageId: 'fake-message-id' }), { status: 201 }));
  return { request, smtp };
}

test('Brevo sends all OTP types over HTTPS without SMTP and preserves leading zeroes', async (t) => {
  const { request, smtp } = setupBrevo(t);
  for (const send of [sendRegistrationOtp, sendLoginOtp, sendPasswordResetOtp]) {
    await send('patient@example.com', '001234');
  }
  assert.equal(request.mock.callCount(), 3);
  const [url, options] = request.mock.calls[0].arguments;
  assert.equal(url, 'https://api.brevo.com/v3/smtp/email');
  assert.equal(options.headers['api-key'], 'fake-api-key');
  assert.equal(options.method, 'POST');
  assert.ok(options.signal instanceof AbortSignal);
  const body = JSON.parse(options.body);
  assert.equal(body.sender.email, 'sender@example.com');
  assert.equal(body.to[0].email, 'patient@example.com');
  assert.ok(body.textContent.includes('001234'));
  assert.match(JSON.parse(request.mock.calls[2].arguments[1].body).subject, /Reset/);
  assert.equal(smtp.mock.callCount(), 0);
});

test('Brevo missing credentials or invalid sender fail before any network request', async (t) => {
  const { request } = setupBrevo(t);
  delete process.env.BREVO_API_KEY;
  await assert.rejects(sendLoginOtp('patient@example.com', '001234'), /Login email could not be sent/);
  process.env.BREVO_API_KEY = 'fake-api-key';
  process.env.BREVO_SENDER_EMAIL = 'bad';
  await assert.rejects(sendLoginOtp('patient@example.com', '001234'), /Login email could not be sent/);
  assert.equal(request.mock.callCount(), 0);
});

test('Brevo rejection, timeout and malformed responses produce safe errors without SMTP fallback', async (t) => {
  const { request, smtp } = setupBrevo(t);
  for (const status of [400, 401, 429, 500]) {
    request.mock.mockImplementation(async () => new Response('Private provider diagnostic', { status }));
    await assert.rejects(sendPasswordResetOtp('patient@example.com', '001234'), {
      message: 'Password reset email could not be sent.',
    });
  }
  request.mock.mockImplementation(async () => { throw new Error('Private timeout information'); });
  await assert.rejects(sendRegistrationOtp('patient@example.com', '001234'), {
    message: 'Registration email could not be sent.',
  });
  for (const body of ['not JSON', '{}', '{"messageId":""}']) {
    request.mock.mockImplementation(async () => new Response(body, { status: 201 }));
    await assert.rejects(sendLoginOtp('patient@example.com', '001234'), /Login email could not be sent/);
  }
  assert.equal(smtp.mock.callCount(), 0);
});

test('unknown provider and invalid OTP do not make external requests', async (t) => {
  const { request, smtp } = setupBrevo(t);
  await assert.rejects(sendRegistrationOtp('invalid', '001234'), /Valid email/);
  await assert.rejects(sendRegistrationOtp('patient@example.com', 'bad'), /six-digit/);
  process.env.EMAIL_PROVIDER = 'invalid';
  await assert.rejects(sendLoginOtp('patient@example.com', '001234'), /Login email could not be sent/);
  assert.equal(request.mock.callCount(), 0);
  assert.equal(smtp.mock.callCount(), 0);
});
