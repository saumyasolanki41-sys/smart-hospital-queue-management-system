const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { getJwtKey } = require('../services/token.service');

const userRoles = ['patient', 'doctor', 'receptionist', 'admin'];

function unauthorized(res) {
  res.set('WWW-Authenticate', 'Bearer');

  return res.status(401).json({
    success: false,
    error: {
      code: 'UNAUTHORIZED',
      message: 'A valid login token is required.',
    },
  });
}

async function authenticate(req, res, next) {
  res.set('Cache-Control', 'no-store');

  const header = req.get('Authorization');

  if (typeof header !== 'string' || header.length > 8192) {
    return unauthorized(res);
  }

  const match = header.match(/^Bearer ([^\s]+)$/i);

  if (!match) {
    return unauthorized(res);
  }

  const token = match[1];

  try {
    const key = getJwtKey();
    let payload;

    try {
      payload = jwt.verify(token, key, {
        algorithms: ['HS256'],
        issuer: 'hospital-queue-api',
        audience: 'hospital-queue-clients',
        maxAge: '15m',
      });
    } catch {
      return unauthorized(res);
    }

    if (
      typeof payload !== 'object' ||
      !payload ||
      typeof payload.exp !== 'number' ||
      typeof payload.sub !== 'string' ||
      !/^[a-f0-9]{24}$/i.test(payload.sub)
    ) {
      return unauthorized(res);
    }

    const user = await User.findById(payload.sub)
      .select('_id name email role emailVerifiedAt tokenVersion')
      .lean();

    if (!user || !user.emailVerifiedAt || !userRoles.includes(user.role)) {
      return unauthorized(res);
    }

    const version = payload.tokenVersion === undefined ? 0 : payload.tokenVersion;
    if (!Number.isInteger(version) || version !== (user.tokenVersion || 0)) {
      return unauthorized(res);
    }

    req.user = {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
    };

    return next();
  } catch (error) {
    return next(error);
  }
}

function allowRoles(...roles) {
  if (roles.length === 0) {
    throw new Error('Specify at least one allowed role.');
  }

  for (const role of roles) {
    if (!userRoles.includes(role)) {
      throw new Error('Specify a valid patient, doctor, receptionist or admin role.');
    }
  }

  return function checkRole(req, res, next) {
    res.set('Cache-Control', 'no-store');

    if (!req.user) {
      return unauthorized(res);
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'FORBIDDEN',
          message: 'You do not have permission to access this resource.',
        },
      });
    }

    return next();
  };
}

module.exports = { authenticate, allowRoles };
