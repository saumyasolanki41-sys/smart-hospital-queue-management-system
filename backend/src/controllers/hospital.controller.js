const hospitalService = require('../services/hospital.service');

function handleError(error, res, next) {
  const codes = ['VALIDATION_ERROR', 'DEPARTMENT_EXISTS', 'DEPARTMENT_NOT_FOUND', 'DOCTOR_NOT_FOUND',
    'DOCTOR_ACCOUNT_NOT_FOUND', 'DOCTOR_ACCOUNT_LINKED'];
  if (!codes.includes(error.code)) return next(error);
  return res.status(error.status).json({
    success: false, error: { code: error.code, message: error.message },
  });
}

async function listDepartments(req, res, next) {
  try {
    const data = await hospitalService.listDepartments(req.query);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function createDepartment(req, res, next) {
  try {
    const data = await hospitalService.createDepartment(req.body);
    return res.status(201).json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function listDoctors(req, res, next) {
  try {
    const data = await hospitalService.listDoctors(req.query);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function getDoctor(req, res, next) {
  try {
    const data = await hospitalService.getDoctor(req.params.id);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function createDoctor(req, res, next) {
  try {
    const data = await hospitalService.createDoctor(req.body);
    return res.status(201).json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

async function updateDoctor(req, res, next) {
  try {
    const data = await hospitalService.updateDoctor(req.params.id, req.body);
    return res.json({ success: true, data });
  } catch (error) { return handleError(error, res, next); }
}

module.exports = { listDepartments, createDepartment, listDoctors, getDoctor, createDoctor, updateDoctor };
