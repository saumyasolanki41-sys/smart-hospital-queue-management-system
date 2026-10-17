const validator = require('validator');
const createMailTransport = require('../config/mail');

async function sendOtpEmail(email, otp, purpose) {
  if (typeof email !== 'string' || !validator.isEmail(email)) {
    throw new Error('Valid email is required.');
  }

  if (typeof otp !== 'string' || !/^\d{6}$/.test(otp)) {
    throw new Error('OTP must be a six-digit string.');
  }

  const transporter = createMailTransport();

  try {
    const result = await transporter.sendMail({
      from: {
        name: 'Hospital Queue',
        address: process.env.SMTP_USER.trim(),
      },
      to: email,
      subject: purpose === 'login'
        ? 'Your Hospital Queue login OTP'
        : 'Verify your Hospital Queue registration',
      text: [
        `Your ${purpose} OTP is: ${otp}`,
        '',
        'This OTP expires five minutes after it was generated.',
        'Do not share this code with anyone.',
        `If you did not request ${purpose}, ignore this email.`,
      ].join('\n'),
    });

    if (!result.accepted || result.accepted.length === 0) {
      throw new Error('Email was not accepted.');
    }
  } catch {
    const label = purpose === 'login' ? 'Login' : 'Registration';
    throw new Error(`${label} email could not be sent.`);
  } finally {
    transporter.close();
  }
}

function sendRegistrationOtp(email, otp) {
  return sendOtpEmail(email, otp, 'registration');
}

function sendLoginOtp(email, otp) {
  return sendOtpEmail(email, otp, 'login');
}

module.exports = { sendRegistrationOtp, sendLoginOtp };
