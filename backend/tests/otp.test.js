const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  generateOtp,
  hashOtp,
  verifyOtp,
} = require('../src/services/otp.service');

test('generated OTP contains six digits', () => {
  for (let i = 0; i < 100; i++) {
    assert.match(generateOtp(), /^\d{6}$/);
  }
});

test('OTP hashing and verification work securely', () => {
  const originalSecret = process.env.OTP_HASH_SECRET;

  
  process.env.OTP_HASH_SECRET = 'a'.repeat(64);

  try {
    const otp = '001234';
    const challengeId = 'registration-1';
    const hash = hashOtp(otp, challengeId);

    assert.match(hash, /^[a-f0-9]{64}$/);
    assert.equal(verifyOtp(otp, challengeId, hash), true);

    
    assert.equal(verifyOtp('999999', challengeId, hash), false);
    assert.equal(verifyOtp(otp, 'registration-2', hash), false);

    
    assert.equal(verifyOtp('123', challengeId, hash), false);
    assert.equal(verifyOtp(123456, challengeId, hash), false);
    assert.equal(verifyOtp(otp, challengeId, 'invalid-hash'), false);

    assert.throws(() => hashOtp('123', challengeId), /six-digit/);
    assert.throws(() => hashOtp(otp, ''), /Challenge ID/);

    
    process.env.OTP_HASH_SECRET = 'b'.repeat(64);
    assert.equal(verifyOtp(otp, challengeId, hash), false);

    
    delete process.env.OTP_HASH_SECRET;
    assert.throws(() => hashOtp(otp, challengeId), /OTP_HASH_SECRET/);

    process.env.OTP_HASH_SECRET = 'invalid';
    assert.throws(() => hashOtp(otp, challengeId), /OTP_HASH_SECRET/);
  } finally {
    if (originalSecret === undefined) {
      delete process.env.OTP_HASH_SECRET;
    } else {
      process.env.OTP_HASH_SECRET = originalSecret;
    }
  }
});