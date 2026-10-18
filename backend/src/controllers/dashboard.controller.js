const service = require('../services/dashboard.service');

async function getDashboard(req, res, next) {
  try {
    const data = await service.getDashboard(req.query);
    return res.json({ success: true, data });
  } catch (error) {
    if (error.code !== 'VALIDATION_ERROR') return next(error);
    return res.status(400).json({
      success: false, error: { code: error.code, message: error.message },
    });
  }
}

module.exports = { getDashboard };
