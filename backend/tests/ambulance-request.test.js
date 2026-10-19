const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const mongoose = require('mongoose');
const app = require('../src/app');
const Request = require('../src/models/AmbulanceRequest');
const Ambulance = require('../src/models/Ambulance');
const User = require('../src/models/User');
const service = require('../src/services/ambulance-request.service');
const ambulanceService = require('../src/services/ambulance.service');
const { issueAccessToken } = require('../src/services/token.service');

const patient = { id: '507f1f77bcf86cd799439011', role: 'patient' };
const staff = { id: '507f1f77bcf86cd799439012', role: 'receptionist' };
const requestId = '507f1f77bcf86cd799439013';
const ambulanceId = '507f1f77bcf86cd799439014';
const input = { pickupAddress: 'Gate 2, Test Road', contactPhone: '+919876543210', latitude: 28.6, longitude: 77.4 };
let server;
let base;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api/ambulance-requests`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  const state = { role: 'patient', request: { _id: requestId, patient: patient.id, status: 'pending', active: true, ...input },
    ambulance: { _id: ambulanceId, status: 'available' }, filters: [] };
  const matches = (value, filter) => value && Object.entries(filter).every(([key, expected]) =>
    expected === null ? value[key] == null : String(value[key]) === String(expected));
  function query(read) {
    const chain = {};
    for (const method of ['select', 'populate', 'sort', 'skip', 'limit', 'session']) chain[method] = () => chain;
    chain.lean = async () => read();
    chain.then = (resolve, reject) => Promise.resolve().then(read).then(resolve, reject);
    return chain;
  }
  t.mock.method(User, 'findById', () => query(() => ({ _id: patient.id, role: state.role, emailVerifiedAt: new Date(), tokenVersion: 0 })));
  t.mock.method(Request, 'init', async () => {});
  t.mock.method(Ambulance, 'init', async () => {});
  t.mock.method(mongoose.connection, 'transaction', async (work) => {
    const snapshot = structuredClone({ request: state.request, ambulance: state.ambulance });
    try { return await work({}); }
    catch (error) { Object.assign(state, snapshot); throw error; }
  });
  const create = t.mock.method(Request, 'create', async (data) => {
    if (state.duplicate) throw { code: 11000 };
    state.request = { _id: requestId, ...data };
    return state.request;
  });
  t.mock.method(Request, 'findOne', (filter) => {
    state.filters.push(filter);
    return query(() => {
      if (!matches(state.request, filter)) return null;
      const document = { ...state.request };
      document.save = async () => {
        const { save, ...saved } = document;
        state.request = saved;
      };
      return document;
    });
  });
  t.mock.method(Request, 'find', (filter) => {
    state.filters.push(filter);
    return query(() => matches(state.request, filter) ? [state.request] : []);
  });
  t.mock.method(Request, 'exists', (filter) => query(() => matches(state.request, filter)));
  t.mock.method(Ambulance, 'exists', (filter) => query(() => matches(state.ambulance, filter)));
  const updateRequest = t.mock.method(Request, 'findOneAndUpdate', async (filter, update) => {
    if (!matches(state.request, filter)) return null;
    Object.assign(state.request, update.$set);
    return state.request;
  });
  const updateAmbulance = t.mock.method(Ambulance, 'findOneAndUpdate', (filter, update) => query(() => {
    if (!matches(state.ambulance, filter)) return null;
    Object.assign(state.ambulance, update.$set);
    for (const key of Object.keys(update.$unset || {})) delete state.ambulance[key];
    return state.ambulance;
  }));
  const oldSecret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (oldSecret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = oldSecret;
  });
  return { state, create, updateRequest, updateAmbulance };
}

function send(path, method = 'GET', body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(base + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
}

test('request routes require login and enforce patient/staff roles before mutation', async (t) => {
  const { state, create, updateRequest } = setup(t);
  const token = issueAccessToken(patient.id);
  for (const [path, method, body] of [['', 'POST', input], ['', 'GET'], ['/' + requestId, 'GET'],
    ['/' + requestId + '/assign', 'PATCH', { ambulanceId }], ['/' + requestId + '/complete', 'PATCH', {}],
    ['/' + requestId + '/cancel', 'PATCH', {}]]) {
    assert.equal((await send(path, method, body)).status, 401);
    state.role = 'doctor';
    assert.equal((await send(path, method, body, token)).status, 403);
  }
  state.role = 'patient';
  assert.equal((await send('/' + requestId + '/assign', 'PATCH', { ambulanceId }, token)).status, 403);
  assert.equal((await send('/' + requestId + '/complete', 'PATCH', {}, token)).status, 403);
  state.role = 'admin';
  assert.equal((await send('', 'POST', input, token)).status, 403);
  assert.equal(create.mock.callCount(), 0);
  assert.equal(updateRequest.mock.callCount(), 0);
});

test('patient creates a pending request and duplicate active requests return 409', async (t) => {
  const { state, create } = setup(t);
  const response = await send('', 'POST', input, issueAccessToken(patient.id));
  assert.equal(response.status, 201);
  assert.equal((await response.json()).data.request.status, 'pending');
  assert.equal(create.mock.calls[0].arguments[0].patient, patient.id);
  state.duplicate = true;
  await assert.rejects(service.createRequest(patient.id, input), { code: 'ACTIVE_REQUEST_EXISTS' });
});

test('pickup validation rejects injected ownership, invalid types and coordinates before writes', async (t) => {
  const { create } = setup(t);
  for (const body of [null, [], {}, { ...input, patient: staff.id }, { ...input, status: 'assigned' },
    { ...input, latitude: '28' }, { ...input, latitude: NaN }, { ...input, longitude: 181 },
    { ...input, contactPhone: 9876543210 }, { ...input, pickupAddress: 'x' }]) {
    await assert.rejects(service.createRequest(patient.id, body), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(create.mock.callCount(), 0);
  await service.createRequest(patient.id, { ...input, latitude: 0, longitude: 0 });
});

test('patients cannot read or cancel another patient request; lists always scope ownership', async (t) => {
  const { state } = setup(t);
  state.request.patient = staff.id;
  await assert.rejects(service.getRequest(patient, requestId), { code: 'REQUEST_NOT_FOUND' });
  await assert.rejects(service.cancelRequest(patient, requestId, {}), { code: 'REQUEST_NOT_FOUND' });
  assert.deepEqual((await service.listRequests(patient, {})).requests, []);
  assert.equal(state.filters.at(-1).patient, patient.id);
  assert.equal((await service.listRequests(staff, {})).requests.length, 1);
});

test('assignment reserves vehicle and a second request cannot take it', async (t) => {
  const { state } = setup(t);
  await service.assignRequest(staff, requestId, { ambulanceId });
  assert.equal(state.request.status, 'assigned');
  assert.equal(state.ambulance.status, 'busy');
  assert.equal(state.ambulance.activeRequest, requestId);
  state.request = { ...state.request, _id: '507f1f77bcf86cd799439015', status: 'pending', ambulance: undefined };
  await assert.rejects(service.assignRequest(staff, state.request._id, { ambulanceId }), { code: 'AMBULANCE_UNAVAILABLE' });
  assert.equal(state.request.status, 'pending');
  assert.equal(state.ambulance.activeRequest, requestId);
});

test('unavailable ambulance rolls back request and repeated assignment cannot replace a reservation', async (t) => {
  const { state } = setup(t);
  state.ambulance.status = 'maintenance';
  await assert.rejects(service.assignRequest(staff, requestId, { ambulanceId }), { code: 'AMBULANCE_UNAVAILABLE' });
  assert.equal(state.request.status, 'pending');
  state.ambulance.status = 'available';
  await service.assignRequest(staff, requestId, { ambulanceId });
  await assert.rejects(service.assignRequest(staff, requestId, { ambulanceId }), { code: 'REQUEST_CONFLICT' });
});

test('assigned vehicle cannot be manually freed but staff can update its location', async (t) => {
  const { state } = setup(t);
  await service.assignRequest(staff, requestId, { ambulanceId });
  await assert.rejects(ambulanceService.updateAmbulance(ambulanceId, { status: 'available' }), { code: 'AMBULANCE_ASSIGNED' });
  await ambulanceService.updateAmbulance(ambulanceId, { location: { latitude: 0, longitude: 0 } });
  assert.equal(state.ambulance.status, 'busy');
  assert.equal(state.ambulance.activeRequest, requestId);
});

test('completion releases the exact vehicle once and rejects pending or terminal requests', async (t) => {
  const { state } = setup(t);
  await assert.rejects(service.completeRequest(staff, requestId, {}), { code: 'REQUEST_CONFLICT' });
  await service.assignRequest(staff, requestId, { ambulanceId });
  await service.completeRequest(staff, requestId, {});
  assert.equal(state.request.status, 'completed');
  assert.equal(state.request.active, false);
  assert.ok(state.request.completedAt instanceof Date);
  assert.equal(state.ambulance.status, 'available');
  assert.equal(state.ambulance.activeRequest, undefined);
  await assert.rejects(service.completeRequest(staff, requestId, {}), { code: 'REQUEST_CONFLICT' });
});

test('patient cancels pending only; staff cancellation frees an assigned ambulance', async (t) => {
  const { state } = setup(t);
  await service.cancelRequest(patient, requestId);
  assert.equal(state.request.status, 'cancelled');
  assert.equal(state.request.active, false);
  state.request.status = 'pending';
  state.request.active = true;
  await service.assignRequest(staff, requestId, { ambulanceId });
  await assert.rejects(service.cancelRequest(patient, requestId, {}), { code: 'REQUEST_CONFLICT' });
  assert.equal(state.ambulance.status, 'busy');
  await service.cancelRequest(staff, requestId, {});
  assert.equal(state.ambulance.status, 'available');
  assert.ok(state.request.cancelledAt instanceof Date);
});

test('mismatched reservation prevents completion and preserves the assigned request', async (t) => {
  const { state } = setup(t);
  await service.assignRequest(staff, requestId, { ambulanceId });
  state.ambulance.activeRequest = staff.id;
  await assert.rejects(service.completeRequest(staff, requestId, {}), { code: 'REQUEST_CONFLICT' });
  assert.equal(state.request.status, 'assigned');
  assert.equal(state.ambulance.activeRequest, staff.id);
});

test('invalid IDs, pagination and assignment bodies are rejected', async (t) => {
  setup(t);
  for (const query of [{ limit: '51' }, { page: ['1'] }, { status: ['pending'] }, { patient: staff.id }]) {
    await assert.rejects(service.listRequests(patient, query), { code: 'VALIDATION_ERROR' });
  }
  await assert.rejects(service.getRequest(patient, 'bad'), { code: 'VALIDATION_ERROR' });
  await assert.rejects(service.assignRequest(staff, requestId, { ambulanceId, status: 'completed' }), { code: 'VALIDATION_ERROR' });
  await assert.rejects(service.cancelRequest(patient, requestId, { patient: staff.id }), { code: 'VALIDATION_ERROR' });
});

test('request schema validates coordinates and defines unique active patient and assigned vehicle indexes', async () => {
  const request = new Request({ patient: patient.id, ...input });
  await request.validate();
  request.latitude = 91;
  await assert.rejects(request.validate());
  const indexes = Request.schema.indexes();
  assert.ok(indexes.some(([keys, options]) => keys.patient === 1 && options.unique && options.partialFilterExpression.active));
  assert.ok(indexes.some(([keys, options]) => keys.ambulance === 1 && options.unique && options.partialFilterExpression.status === 'assigned'));
});
