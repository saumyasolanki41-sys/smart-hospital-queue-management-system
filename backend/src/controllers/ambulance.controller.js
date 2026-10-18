const service = require('../services/ambulance.service');

function handleError(error, res, next) {
  if (!['VALIDATION_ERROR', 'VEHICLE_EXISTS', 'AMBULANCE_NOT_FOUND'].includes(error.code)) return next(error);
  return res.status(error.status).json({ success: false, error: { code: error.code, message: error.message } });
}

async function listAmbulances(req, res, next) {
  try {
    const data = await service.listAmbulances(req.query);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function getAmbulance(req, res, next) {
  try {
    const data = await service.getAmbulance(req.params.id);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function createAmbulance(req, res, next) {
  try {
    const data = await service.createAmbulance(req.body);
    return res.status(201).json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function updateAmbulance(req, res, next) {
  try {
    const data = await service.updateAmbulance(req.params.id, req.body);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

module.exports = { listAmbulances, getAmbulance, createAmbulance, updateAmbulance };
