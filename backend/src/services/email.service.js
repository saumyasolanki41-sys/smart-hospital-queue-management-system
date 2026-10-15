const validator = require('validator');
const createMailTransport = require('../config/mail');

async function sendRegistrationOtp(email, otp) {
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
      subject: 'Verify your Hospital Queue registration',
      text: [
        `Your registration OTP is: ${otp}`,
        '',
        'This OTP expires five minutes after it was generated.',
        'Do not share this code with anyone.',
        'If you did not request registration, ignore this email.',
      ].join('\n'),
    });

    if (!result.accepted || result.accepted.length === 0) {
      throw new Error('Email was not accepted.');
    }
  } catch {
    throw new Error('Registration email could not be sent.');
  } finally {
    transporter.close();
  }
}

module.exports = { sendRegistrationOtp };