const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const app = require('../src/app');
const Ambulance = require('../src/models/Ambulance');
const User = require('../src/models/User');
const service = require('../src/services/ambulance.service');
const { issueAccessToken } = require('../src/services/token.service');

const userId = '507f1f77bcf86cd799439011';
const ambulanceId = '507f1f77bcf86cd799439012';
const input = { vehicleNumber: 'UP 14-AB 1234', driverName: 'Test Driver', driverPhone: '+919876543210' };
let server;
let base;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}/api/ambulances`;
});
after(() => new Promise((resolve) => server.close(resolve)));

function setup(t) {
  const state = { role: 'admin', ambulance: { _id: ambulanceId, vehicleNumber: 'UP14AB1234',
    driverName: 'Test Driver', driverPhone: '+919876543210', status: 'available' } };
  function query(value) {
    const chain = {};
    for (const method of ['select', 'sort', 'skip', 'limit']) chain[method] = t.mock.fn(() => chain);
    chain.lean = async () => {
      if (state.error) throw state.error;
      return value();
    };
    return chain;
  }
  t.mock.method(Ambulance, 'init', async () => {});
  t.mock.method(User, 'findById', () => query(() => ({
    _id: userId, role: state.role, emailVerifiedAt: new Date(), tokenVersion: 0,
  })));
  const list = query(() => [state.ambulance]);
  const find = t.mock.method(Ambulance, 'find', () => list);
  const findById = t.mock.method(Ambulance, 'findById', () => query(() => state.ambulance));
  const create = t.mock.method(Ambulance, 'create', async () => {
    if (state.writeError) throw state.writeError;
    return state.ambulance;
  });
  const update = t.mock.method(Ambulance, 'findByIdAndUpdate', () => {
    if (state.writeError) throw state.writeError;
    return query(() => state.ambulance);
  });
  const secret = process.env.JWT_SECRET;
  process.env.JWT_SECRET = 'a'.repeat(64);
  t.after(() => {
    if (secret === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = secret;
  });
  return { state, list, find, findById, create, update };
}

function request(path = '', method = 'GET', body, token) {
  const headers = {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(base + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
}

test('ambulance details including driver contacts and location require authorized staff', async (t) => {
  const { state, find, create, update } = setup(t);
  for (const [path, method, body] of [['', 'GET'], ['/' + ambulanceId, 'GET'],
    ['', 'POST', input], ['/' + ambulanceId, 'PATCH', { status: 'busy' }]]) {
    assert.equal((await request(path, method, body)).status, 401);
    for (const role of ['patient', 'doctor']) {
      state.role = role;
      assert.equal((await request(path, method, body, issueAccessToken(userId))).status, 403);
    }
  }
  assert.equal(find.mock.callCount(), 0);
  assert.equal(create.mock.callCount(), 0);
  assert.equal(update.mock.callCount(), 0);
});

test('admin can create a normalized vehicle and receptionist cannot create one', async (t) => {
  const { state, create } = setup(t);
  const token = issueAccessToken(userId);
  const response = await request('', 'POST', input, token);
  assert.equal(response.status, 201);
  assert.equal((await response.json()).data.ambulance.vehicleNumber, 'UP14AB1234');
  assert.equal(create.mock.calls[0].arguments[0].vehicleNumber, 'UP14AB1234');
  state.role = 'receptionist';
  assert.equal((await request('', 'POST', input, token)).status, 403);
  assert.equal(create.mock.callCount(), 1);
});

test('staff list supports status filtering and bounded pagination', async (t) => {
  const { state, find, list } = setup(t);
  state.role = 'receptionist';
  const response = await request('?status=available&page=2&limit=5', 'GET', undefined, issueAccessToken(userId));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(find.mock.calls[0].arguments[0], { status: 'available' });
  assert.equal(list.skip.mock.calls[0].arguments[0], 5);
  assert.equal(list.limit.mock.calls[0].arguments[0], 5);
});

test('receptionist can update location and server assigns the location timestamp', async (t) => {
  const { state, update } = setup(t);
  state.role = 'receptionist';
  const response = await request('/' + ambulanceId, 'PATCH', {
    status: 'busy', location: { latitude: 28.6692, longitude: 77.4538 },
  }, issueAccessToken(userId));
  assert.equal(response.status, 200);
  const [id, changes, options] = update.mock.calls[0].arguments;
  assert.equal(id, ambulanceId);
  assert.equal(changes.$set.status, 'busy');
  assert.deepEqual(Object.keys(changes.$set.location).sort(), ['latitude', 'longitude', 'updatedAt']);
  assert.ok(changes.$set.location.updatedAt instanceof Date);
  assert.equal(options.runValidators, true);
});

test('duplicate normalized vehicle numbers return safe 409 on create and update', async (t) => {
  const { state } = setup(t);
  state.writeError = { code: 11000 };
  await assert.rejects(service.createAmbulance({ ...input, vehicleNumber: 'up14-ab1234' }), { code: 'VEHICLE_EXISTS' });
  await assert.rejects(service.updateAmbulance(ambulanceId, { vehicleNumber: 'UP14AB1234' }), { code: 'VEHICLE_EXISTS' });
});

test('invalid body fields, phone, vehicle and injected updates fail before writes', async (t) => {
  const { create, update } = setup(t);
  for (const body of [null, [], {}, { ...input, vehicleNumber: 'ABC' },
    { ...input, vehicleNumber: 'UP14\nAB1234' }, { ...input, driverPhone: 9876543210 },
    { ...input, driverPhone: 'bad' }, { ...input, driverName: 'x' },
    { ...input, status: 'unknown' }, { ...input, role: 'admin' }]) {
    await assert.rejects(service.createAmbulance(body), { code: 'VALIDATION_ERROR' });
  }
  for (const body of [{}, { $set: { status: 'available' } }, { status: ['available'] }, { driverName: 'bad\nname' }]) {
    await assert.rejects(service.updateAmbulance(ambulanceId, body), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(create.mock.callCount(), 0);
  assert.equal(update.mock.callCount(), 0);
});

test('locations reject invalid ranges, partial coordinates and caller-controlled timestamps', async (t) => {
  const { update } = setup(t);
  for (const location of [null, [], {}, { latitude: 91, longitude: 0 },
    { latitude: 0, longitude: -181 }, { latitude: '28', longitude: 77 },
    { latitude: NaN, longitude: 77 }, { latitude: 0, longitude: Infinity },
    { latitude: 0 }, { latitude: 0, longitude: 0, updatedAt: '2020-01-01' }]) {
    await assert.rejects(service.updateAmbulance(ambulanceId, { location }), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(update.mock.callCount(), 0);
  await service.updateAmbulance(ambulanceId, { location: { latitude: 0, longitude: 0 } });
  assert.equal(update.mock.calls[0].arguments[1].$set.location.latitude, 0);
});

test('bad IDs and filters fail before reads and missing vehicles return 404', async (t) => {
  const { state, find, findById } = setup(t);
  await assert.rejects(service.getAmbulance('bad'), { code: 'VALIDATION_ERROR' });
  for (const query of [{ status: { $ne: null } }, { status: ['available'] }, { status: 'bad' },
    { page: '0' }, { page: '100001' }, { limit: '51' }, { driverPhone: 'private' }]) {
    await assert.rejects(service.listAmbulances(query), { code: 'VALIDATION_ERROR' });
  }
  assert.equal(find.mock.callCount(), 0);
  assert.equal(findById.mock.callCount(), 0);
  state.ambulance = null;
  await assert.rejects(service.getAmbulance(ambulanceId), { code: 'AMBULANCE_NOT_FOUND' });
  await assert.rejects(service.updateAmbulance(ambulanceId, { status: 'maintenance' }), { code: 'AMBULANCE_NOT_FOUND' });
});

test('database failure stays private and schema validates location and unique vehicle identity', async (t) => {
  const { state } = setup(t);
  state.error = new Error('Private connection details');
  const response = await request('', 'GET', undefined, issueAccessToken(userId));
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.message, 'An unexpected error occurred.');
  const vehicle = new Ambulance({ ...input, vehicleNumber: 'UP14AB1234' });
  await vehicle.validate();
  assert.equal(vehicle.status, 'available');
  assert.equal(vehicle.location, undefined);
  vehicle.location = { latitude: 100, longitude: 0, updatedAt: new Date() };
  await assert.rejects(vehicle.validate());
  assert.equal(Ambulance.schema.path('vehicleNumber').options.unique, true);
});
