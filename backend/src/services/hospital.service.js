const Department = require('../models/Department');
const Doctor = require('../models/Doctor');

function hospitalError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function validId(id) {
  if (typeof id !== 'string' || !/^[a-f0-9]{24}$/i.test(id)) {
    throw hospitalError(400, 'VALIDATION_ERROR', 'Send a valid ID.');
  }
  return id;
}

function checkFields(body, allowed) {
  if (!body || typeof body !== 'object' || Array.isArray(body) ||
      Object.keys(body).length === 0 || Object.keys(body).some((field) => !allowed.includes(field))) {
    throw hospitalError(400, 'VALIDATION_ERROR', 'Send only the supported fields.');
  }
}

function text(value, label, min, max) {
  if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max ||
      /[\u0000-\u001f\u007f]/.test(value)) {
    throw hospitalError(400, 'VALIDATION_ERROR', `${label} must contain ${min} to ${max} characters.`);
  }
  return value.trim();
}

function pagination(query, allowed) {
  if (Object.keys(query).some((key) => !allowed.includes(key))) {
    throw hospitalError(400, 'VALIDATION_ERROR', 'Unsupported query parameter.');
  }
  const page = query.page === undefined ? '1' : query.page;
  const limit = query.limit === undefined ? '20' : query.limit;
  if (typeof page !== 'string' || !/^[1-9]\d*$/.test(page) || Number(page) > 100000 ||
      typeof limit !== 'string' || !/^[1-9]\d*$/.test(limit) || Number(limit) > 50) {
    throw hospitalError(400, 'VALIDATION_ERROR', 'Page must be 1–100000 and limit must be 1–50.');
  }
  return { page: Number(page), limit: Number(limit) };
}

async function listDepartments(query) {
  const { page, limit } = pagination(query, ['page', 'limit']);
  const departments = await Department.find().select('name description')
    .sort({ name: 1, _id: 1 }).skip((page - 1) * limit).limit(limit).lean();
  return { departments, page, limit };
}

async function createDepartment(body) {
  checkFields(body, ['name', 'description']);
  const name = text(body.name, 'Name', 2, 100);
  const description = body.description === undefined ? '' : text(body.description, 'Description', 0, 500);
  await Department.init();
  try {
    const department = await Department.create({ name, description });
    return { department: { _id: department._id, name: department.name, description: department.description } };
  } catch (error) {
    if (error.code === 11000) {
      throw hospitalError(409, 'DEPARTMENT_EXISTS', 'A department with this name already exists.');
    }
    throw error;
  }
}

function doctorFields(body, updating) {
  checkFields(body, ['name', 'departmentId', 'specialization', 'experienceYears', 'consultationFee', 'isAvailable']);
  const data = {};
  if (!updating || body.name !== undefined) data.name = text(body.name, 'Name', 2, 100);
  if (!updating || body.specialization !== undefined) {
    data.specialization = text(body.specialization, 'Specialization', 2, 100);
  }
  if (!updating || body.departmentId !== undefined) data.department = validId(body.departmentId);
  if (body.experienceYears !== undefined) {
    if (!Number.isInteger(body.experienceYears) || body.experienceYears < 0 || body.experienceYears > 80) {
      throw hospitalError(400, 'VALIDATION_ERROR', 'Experience must be an integer from 0 to 80.');
    }
    data.experienceYears = body.experienceYears;
  }
  if (body.consultationFee !== undefined) {
    if (typeof body.consultationFee !== 'number' || !Number.isFinite(body.consultationFee) ||
        body.consultationFee < 0 || body.consultationFee > 100000) {
      throw hospitalError(400, 'VALIDATION_ERROR', 'Consultation fee must be a number from 0 to 100000.');
    }
    data.consultationFee = body.consultationFee;
  }
  if (body.isAvailable !== undefined) {
    if (typeof body.isAvailable !== 'boolean') {
      throw hospitalError(400, 'VALIDATION_ERROR', 'isAvailable must be a boolean.');
    }
    data.isAvailable = body.isAvailable;
  }
  return data;
}

async function checkDepartment(id) {
  if (!await Department.exists({ _id: id })) {
    throw hospitalError(404, 'DEPARTMENT_NOT_FOUND', 'Department not found.');
  }
}

const doctorSelection = 'name department specialization experienceYears consultationFee isAvailable';

async function listDoctors(query) {
  const { page, limit } = pagination(query, ['page', 'limit', 'departmentId', 'isAvailable']);
  const filter = {};
  if (query.departmentId !== undefined) filter.department = validId(query.departmentId);
  if (query.isAvailable !== undefined) {
    if (!['true', 'false'].includes(query.isAvailable)) {
      throw hospitalError(400, 'VALIDATION_ERROR', 'isAvailable must be true or false.');
    }
    filter.isAvailable = query.isAvailable === 'true';
  }
  const doctors = await Doctor.find(filter).select(doctorSelection).populate('department', 'name')
    .sort({ name: 1, _id: 1 }).skip((page - 1) * limit).limit(limit).lean();
  return { doctors, page, limit };
}

async function getDoctor(id) {
  const doctor = await Doctor.findById(validId(id)).select(doctorSelection)
    .populate('department', 'name').lean();
  if (!doctor) throw hospitalError(404, 'DOCTOR_NOT_FOUND', 'Doctor not found.');
  return { doctor };
}

async function createDoctor(body) {
  const data = doctorFields(body, false);
  await checkDepartment(data.department);
  const doctor = await Doctor.create(data);
  return getDoctor(doctor._id.toString());
}

async function updateDoctor(id, body) {
  validId(id);
  const data = doctorFields(body, true);
  if (data.department) await checkDepartment(data.department);
  const doctor = await Doctor.findByIdAndUpdate(id, { $set: data }, {
    returnDocument: 'after', runValidators: true,
  }).select(doctorSelection).populate('department', 'name').lean();
  if (!doctor) throw hospitalError(404, 'DOCTOR_NOT_FOUND', 'Doctor not found.');
  return { doctor };
}

module.exports = { listDepartments, createDepartment, listDoctors, getDoctor, createDoctor, updateDoctor };
