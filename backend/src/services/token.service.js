const jwt = require('jsonwebtoken');

function getJwtKey() {
  const secret = process.env.JWT_SECRET;

  if (!secret || !/^[a-f0-9]{64}$/i.test(secret)) {
    throw new Error('Configure a 64-character hexadecimal JWT_SECRET.');
  }

  return Buffer.from(secret, 'hex');
}

function issueAccessToken(userId, tokenVersion = 0) {
  return jwt.sign({ tokenVersion }, getJwtKey(), {
    algorithm: 'HS256',
    subject: userId.toString(),
    issuer: 'hospital-queue-api',
    audience: 'hospital-queue-clients',
    expiresIn: '15m',
  });
}

module.exports = { getJwtKey, issueAccessToken };
