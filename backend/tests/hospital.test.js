const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../src/app');
const Department = require('../src/models/Department');
const Doctor = require('../src/models/Doctor');
const User = require('../src/models/User');
const service = require('../src/services/hospital.service');
const { issueAccessToken } = require('../src/services/token.service');

const departmentId = '507f1f77bcf86cd799439011';
const doctorId = '507f1f77bcf86cd799439012';
const body = {
  name: 'Dr Test Patient', departmentId, specialization: 'Cardiologist',
  experienceYears: 5, consultationFee: 500, isAvailable: true,
};
let server;
let base;

before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  const state = {
    department: { _id: departmentId, name: 'Cardiology', description: 'Heart care' },
    doctor: { _id: doctorId, name: body.name, department: { _id: departmentId, name: 'Cardiology' },
      specialization: body.specialization, experienceYears: 5, consultationFee: 500, isAvailable: true },
    departmentExists: true,
    role: 'admin',
  };
  function query(value) {
    const chain = {};
    for (const method of ['select', 'populate', 'sort', 'skip', 'limit']) {
      chain[method] = t.mock.fn(() => chain);
    }
    chain.lean = async () => {
      if (state.error) throw state.error;
      return value();
    };
    return chain;
  }
  const departments = query(() => [state.department]);
  const doctors = query(() => [state.doctor]);
  const findDepartments = t.mock.method(Department, 'find', () => departments);
  const findDoctors = t.mock.method(Doctor, 'find', () => doctors);
  t.mock.method(Department, 'init', async () => {});
  t.mock.method(Doctor, 'init', async () => {});
  const exists = t.mock.method(Department, 'exists', async () => state.departmentExists);
  const createDepartment = t.mock.method(Department, 'create', async () => {
    if (state.error) throw state.error;
    return state.department;
  });
  const createDoctor = t.mock.method(Doctor, 'create', async () => state.doctor);
  t.mock.method(Doctor, 'findById', () => query(() => state.doctor));
  const updateDoctor = t.mock.method(Doctor, 'findByIdAndUpdate', () => query(() => state.doctor));
  t.mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => ({
    _id: departmentId, name: 'Test Admin', email: 'admin@example.com',
    role: state.role, emailVerifiedAt: new Date(), tokenVersion: 0,
  }) }) }));
  const secret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (secret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = secret;
  });
  return { state, departments, doctors, exists, createDepartment, createDoctor,
    findDepartments, findDoctors, updateDoctor };
}

async function request(path, method = 'GET', data, token) {
  const headers = {};
  if (data !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(base + path, {
    method, headers, body: data === undefined ? undefined : JSON.stringify(data),
  });
}

test('public department and doctor lists are paginated and return directory data', async (t) => {
  const { state, departments, doctors, findDoctors } = setup(t);
  const response = await request('/api/departments?page=2&limit=5');
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).data, { departments: [state.department], page: 2, limit: 5 });
  assert.equal(departments.skip.mock.calls[0].arguments[0], 5);
  const filtered = await request(`/api/doctors?departmentId=${departmentId}&isAvailable=false&limit=3`);
  assert.equal(filtered.status, 200);
  assert.deepEqual(findDoctors.mock.calls[0].arguments[0], { department: departmentId, isAvailable: false });
  assert.equal(doctors.limit.mock.calls[0].arguments[0], 3);
  const detail = await request('/api/doctors/' + doctorId);
  assert.deepEqual((await detail.json()).data, { doctor: state.doctor });
});

test('invalid query parameters and IDs fail before database reads', async (t) => {
  const { findDepartments, findDoctors } = setup(t);
  for (const query of [{ page: '0' }, { page: '-1' }, { page: '1.5' }, { page: '100001' },
    { limit: '51' }, { page: ['1', '2'] }, { limit: '' }, { role: 'admin' }]) {
    await assert.rejects(service.listDepartments(query), { code: 'VALIDATION_ERROR' });
  }
  for (const query of [{ departmentId: { $ne: null } }, { isAvailable: 'yes' },
    { isAvailable: ['true', 'false'] }]) {
    await assert.rejects(service.listDoctors(query), { code: 'VALIDATION_ERROR' });
  }
  const result = await request('/api/doctors/not-an-id');
  assert.equal(result.status, 400);
  assert.equal(findDepartments.mock.callCount(), 0);
  assert.equal(findDoctors.mock.callCount(), 0);
});

test('hospital mutations require authentication and only allow admin', async (t) => {
  const { state, createDepartment, createDoctor, updateDoctor } = setup(t);
  const mutations = [
    ['/api/departments', 'POST', { name: 'Cardiology' }],
    ['/api/doctors', 'POST', body], ['/api/doctors/' + doctorId, 'PATCH', { isAvailable: false }],
  ];
  for (const [path, method, data] of mutations) {
    assert.equal((await request(path, method, data)).status, 401);
    for (const role of ['patient', 'doctor', 'receptionist']) {
      state.role = role;
      assert.equal((await request(path, method, data, issueAccessToken(departmentId))).status, 403);
    }
  }
  assert.equal(createDepartment.mock.callCount(), 0);
  assert.equal(createDoctor.mock.callCount(), 0);
  assert.equal(updateDoctor.mock.callCount(), 0);
});

test('admin can create a department and duplicate names return 409', async (t) => {
  const { state, createDepartment } = setup(t);
  const token = issueAccessToken(departmentId);
  const result = await request('/api/departments', 'POST', { name: ' Cardiology ' }, token);
  assert.equal(result.status, 201);
  assert.deepEqual(createDepartment.mock.calls[0].arguments[0], { name: 'Cardiology', description: '' });
  state.error = { code: 11000 };
  const duplicate = await request('/api/departments', 'POST', { name: 'cardiology' }, token);
  assert.equal(duplicate.status, 409);
  assert.equal((await duplicate.json()).error.code, 'DEPARTMENT_EXISTS');
});

test('invalid department input cannot reach a write', async (t) => {
  const { createDepartment } = setup(t);
  for (const data of [null, [], {}, { name: 'a' }, { name: 'a'.repeat(101) },
    { name: 'Bad\nName' }, { name: 'Valid', description: 123 }, { name: 'Valid', role: 'admin' }]) {
    await assert.rejects(service.createDepartment(data), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(createDepartment.mock.callCount(), 0);
});

test('admin creates a doctor linked to an existing department', async (t) => {
  const { createDoctor } = setup(t);
  const result = await request('/api/doctors', 'POST', body, issueAccessToken(departmentId));
  assert.equal(result.status, 201);
  const saved = createDoctor.mock.calls[0].arguments[0];
  assert.equal(saved.department, departmentId);
  assert.equal(saved.departmentId, undefined);
  assert.equal(saved.name, body.name);
});

test('doctor writes reject missing departments, invalid values and privileged fields', async (t) => {
  const { state, createDoctor, updateDoctor } = setup(t);
  for (const data of [{}, { ...body, departmentId: 'bad' }, { ...body, specialization: '' },
    { ...body, experienceYears: 1.5 }, { ...body, experienceYears: -1 },
    { ...body, consultationFee: '500' }, { ...body, consultationFee: Infinity },
    { ...body, consultationFee: -1 }, { ...body, isAvailable: 'false' },
    { ...body, role: 'admin' }, { ...body, userId: 'bad' }]) {
    await assert.rejects(service.createDoctor(data), { code: 'VALIDATION_ERROR' });
  }
  await assert.rejects(service.updateDoctor(doctorId, {}), { code: 'VALIDATION_ERROR' });
  state.departmentExists = false;
  await assert.rejects(service.createDoctor(body), { code: 'DEPARTMENT_NOT_FOUND' });
  await assert.rejects(service.updateDoctor(doctorId, { departmentId }), { code: 'DEPARTMENT_NOT_FOUND' });
  assert.equal(createDoctor.mock.callCount(), 0);
  assert.equal(updateDoctor.mock.callCount(), 0);
});

test('doctor updates use validated fields and missing doctors return 404', async (t) => {
  const { state, updateDoctor } = setup(t);
  const token = issueAccessToken(departmentId);
  assert.equal((await request('/api/doctors/' + doctorId, 'PATCH', { isAvailable: false }, token)).status, 200);
  assert.deepEqual(updateDoctor.mock.calls[0].arguments[1], { $set: { isAvailable: false } });
  assert.equal(updateDoctor.mock.calls[0].arguments[2].runValidators, true);
  state.doctor = null;
  assert.equal((await request('/api/doctors/' + doctorId)).status, 404);
  assert.equal((await request('/api/doctors/' + doctorId, 'PATCH', { consultationFee: 0 }, token)).status, 404);
});

test('database failures stay private and PATCH is accepted by CORS preflight', async (t) => {
  const { state } = setup(t);
  state.error = new Error('Private database connection details');
  const response = await request('/api/departments');
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.message, 'An unexpected error occurred.');
  const preflight = await fetch(base + '/api/doctors/' + doctorId, {
    method: 'OPTIONS', headers: {
      Origin: 'http://localhost:5173', 'Access-Control-Request-Method': 'PATCH',
      'Access-Control-Request-Headers': 'authorization,content-type',
    },
  });
  assert.equal(preflight.status, 204);
  assert.ok(preflight.headers.get('access-control-allow-methods').includes('PATCH'));
});

test('models enforce directory fields and department name uniqueness index', async () => {
  await new Department({ name: 'Cardiology' }).validate();
  await new Doctor({ name: body.name, department: departmentId, specialization: body.specialization }).validate();
  await assert.rejects(new Doctor({ name: 'Dr Test', specialization: 'Cardiology' }).validate());
  const index = Department.schema.indexes().find(([fields]) => fields.name === 1);
  assert.equal(index[1].unique, true);
  assert.equal(index[1].collation.strength, 2);
});

test('admin profile linking requires a verified doctor account and stores only its ID', async (t) => {
  const { state, updateDoctor } = setup(t);
  await assert.rejects(service.updateDoctor(doctorId, { userId: departmentId }), {
    code: 'DOCTOR_ACCOUNT_NOT_FOUND',
  });
  state.role = 'doctor';
  await service.updateDoctor(doctorId, { userId: departmentId });
  assert.deepEqual(updateDoctor.mock.calls[0].arguments[1], { $set: { user: departmentId } });
  t.mock.method(User, 'findById', () => ({ select: () => ({ lean: async () => null }) }));
  await assert.rejects(service.updateDoctor(doctorId, { userId: departmentId }), {
    code: 'DOCTOR_ACCOUNT_NOT_FOUND',
  });
});

test('an already linked doctor account produces a safe 409 conflict', async (t) => {
  const { state, createDoctor } = setup(t);
  state.role = 'doctor';
  createDoctor.mock.mockImplementation(async () => { throw { code: 11000 }; });
  await assert.rejects(service.createDoctor({ ...body, userId: departmentId }), {
    code: 'DOCTOR_ACCOUNT_LINKED', status: 409,
  });
  const userField = Doctor.schema.path('user');
  assert.equal(userField.options.unique, true);
  assert.equal(userField.options.sparse, true);
});

test('average consultation time accepts whole minutes only within the allowed range', async (t) => {
  const { updateDoctor, createDoctor } = setup(t);
  for (const duration of [0, -1, 121, 1.5, '10', null]) {
    await assert.rejects(service.updateDoctor(doctorId, { averageConsultationMinutes: duration }), {
      code: 'VALIDATION_ERROR',
    });
    await assert.rejects(service.createDoctor({ ...body, averageConsultationMinutes: duration }), {
      code: 'VALIDATION_ERROR',
    });
  }
  assert.equal(createDoctor.mock.callCount(), 0);
  assert.equal(updateDoctor.mock.callCount(), 0);
  await service.updateDoctor(doctorId, { averageConsultationMinutes: 15 });
  assert.deepEqual(updateDoctor.mock.calls[0].arguments[1], { $set: { averageConsultationMinutes: 15 } });
  const doctor = new Doctor({ name: body.name, department: departmentId, specialization: body.specialization });
  assert.equal(doctor.averageConsultationMinutes, 10);
  doctor.averageConsultationMinutes = 0;
  await assert.rejects(doctor.validate());
});
