const validator = require('validator');
const createMailTransport = require('../config/mail');

async function sendWithBrevo(email, subject, text) {
  const apiKey = process.env.BREVO_API_KEY?.trim();
  const sender = process.env.BREVO_SENDER_EMAIL?.trim();

  if (!apiKey || !sender || !validator.isEmail(sender)) {
    throw new Error('Configure BREVO_API_KEY and a verified BREVO_SENDER_EMAIL.');
  }

  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'api-key': apiKey },
    body: JSON.stringify({
      sender: { name: 'Hospital Queue', email: sender },
      to: [{ email }],
      subject,
      textContent: text,
    }),
    signal: AbortSignal.timeout(10000),
  });

  if (response.status !== 201) {
    throw new Error('Email provider rejected the request.');
  }
  const result = await response.json();
  if (typeof result.messageId !== 'string' || !result.messageId) {
    throw new Error('Email provider did not accept the message.');
  }
}

async function sendOtpEmail(email, otp, purpose) {
  if (typeof email !== 'string' || !validator.isEmail(email)) {
    throw new Error('Valid email is required.');
  }

  if (typeof otp !== 'string' || !/^\d{6}$/.test(otp)) {
    throw new Error('OTP must be a six-digit string.');
  }

  let subject = 'Verify your Hospital Queue registration';
  if (purpose === 'login') subject = 'Your Hospital Queue login OTP';
  if (purpose === 'password reset') subject = 'Reset your Hospital Queue password';
  const text = [
    `Your ${purpose} OTP is: ${otp}`,
    '',
    'This OTP expires five minutes after it was generated.',
    'Do not share this code with anyone.',
    `If you did not request ${purpose}, ignore this email.`,
  ].join('\n');

  let transporter;
  try {
    const provider = process.env.EMAIL_PROVIDER || 'smtp';
    if (provider === 'brevo') {
      await sendWithBrevo(email, subject, text);
      return;
    }
    if (provider !== 'smtp') {
      throw new Error('Unsupported EMAIL_PROVIDER.');
    }
    transporter = createMailTransport();
    const result = await transporter.sendMail({
      from: {
        name: 'Hospital Queue',
        address: process.env.SMTP_USER.trim(),
      },
      to: email,
      subject,
      text,
    });

    if (!result.accepted || result.accepted.length === 0) {
      throw new Error('Email was not accepted.');
    }
  } catch {
    let label = 'Registration';
    if (purpose === 'login') label = 'Login';
    if (purpose === 'password reset') label = 'Password reset';
    throw new Error(`${label} email could not be sent.`);
  } finally {
    if (transporter) transporter.close();
  }
}

function sendRegistrationOtp(email, otp) {
  return sendOtpEmail(email, otp, 'registration');
}

function sendLoginOtp(email, otp) {
  return sendOtpEmail(email, otp, 'login');
}

function sendPasswordResetOtp(email, otp) {
  return sendOtpEmail(email, otp, 'password reset');
}

module.exports = { sendRegistrationOtp, sendLoginOtp, sendPasswordResetOtp };
