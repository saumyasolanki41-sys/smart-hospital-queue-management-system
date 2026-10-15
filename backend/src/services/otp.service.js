const crypto = require('node:crypto');

function getOtpSecret() {
  const secret = process.env.OTP_HASH_SECRET;

  if (!secret || !/^[a-f0-9]{64}$/i.test(secret)) {
    throw new Error('OTP_HASH_SECRET must contain 64 hexadecimal characters.');
  }

  return Buffer.from(secret, 'hex');
}

function generateOtp() {
  return crypto.randomInt(0, 1000000).toString().padStart(6, '0');
}

function hashOtp(otp, challengeId) {
  if (typeof otp !== 'string' || !/^\d{6}$/.test(otp)) {
    throw new Error('OTP must be a six-digit string.');
  }

  if (typeof challengeId !== 'string' || !challengeId.trim()) {
    throw new Error('Challenge ID is required.');
  }

  const input = JSON.stringify([
    'registration',
    challengeId,
    otp,
  ]);

  return crypto
    .createHmac('sha256', getOtpSecret())
    .update(input)
    .digest('hex');
}

function verifyOtp(otp, challengeId, storedHash) {
  if (typeof otp !== 'string' || !/^\d{6}$/.test(otp)) {
    return false;
  }

  if (
    typeof storedHash !== 'string' ||
    !/^[a-f0-9]{64}$/.test(storedHash)
  ) {
    return false;
  }

  const incomingHash = hashOtp(otp, challengeId);

  return crypto.timingSafeEqual(
    Buffer.from(incomingHash, 'hex'),
    Buffer.from(storedHash, 'hex')
  );
}

module.exports = {
  generateOtp,
  hashOtp,
  verifyOtp,
};