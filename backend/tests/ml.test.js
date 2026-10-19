const { test } = require('node:test');
const assert = require('node:assert/strict');
const ml = require('../src/services/ml.service');
const travel = require('../src/services/travel.service');

function env(t, key, value) {
  const previous = process.env[key];
  if (value === undefined) delete process.env[key];
  else process.env[key] = value;
  t.after(() => {
    if (previous === undefined) delete process.env[key];
    else process.env[key] = previous;
  });
}

test('ML numeric results are validated, rounded and briefly cached', async (t) => {
  env(t, 'ML_SERVICE_URL', 'https://ml.example/success');
  const fetch = t.mock.method(global, 'fetch', async () => Response.json({ eta_minutes: 12.345 }));
  const result = await ml.predict('/predict/ambulance-eta', { Distance_to_Incident: 3 }, 'eta_minutes', 5);
  assert.deepEqual(result, { minutes: 12.35, source: 'ml', reason: null });
  await ml.predict('/predict/ambulance-eta', { Distance_to_Incident: 3 }, 'eta_minutes', 5);
  assert.equal(fetch.mock.callCount(), 1);
  const [url, options] = fetch.mock.calls[0].arguments;
  assert.equal(url.pathname, '/predict/ambulance-eta');
  assert.equal(options.redirect, 'error');
  assert.ok(options.signal instanceof AbortSignal);
});

test('missing ML configuration returns baseline without external traffic', async (t) => {
  env(t, 'ML_SERVICE_URL', undefined);
  const fetch = t.mock.method(global, 'fetch', async () => { throw new Error('Unexpected network'); });
  assert.equal((await ml.predict('/predict/queue-time', {}, 'wait_time_minutes', 15)).reason, 'ml_not_configured');
  assert.equal(fetch.mock.callCount(), 0);
});

test('ML rejects malformed, negative, string and unbounded predictions', async (t) => {
  env(t, 'ML_SERVICE_URL', 'https://invalid.example');
  let value;
  t.mock.method(global, 'fetch', async () => Response.json({ eta_minutes: value }));
  for (const input of [-1, '12', null, 10081, undefined]) {
    value = input;
    const result = await ml.predict('/predict/ambulance-eta', { value: input }, 'eta_minutes', 8);
    assert.equal(result.minutes, 8);
    assert.equal(result.reason, 'ml_invalid_response');
  }
});

test('ML retries transient errors once but never retries rejected input', async (t) => {
  env(t, 'ML_SERVICE_URL', 'https://retry.example');
  let status = 503;
  const fetch = t.mock.method(global, 'fetch', async () => Response.json({}, { status }));
  assert.equal((await ml.predict('/predict/queue-time', {}, 'wait_time_minutes', 8)).reason, 'ml_unavailable');
  assert.equal(fetch.mock.callCount(), 2);
  status = 422;
  assert.equal((await ml.predict('/predict/queue-time', {}, 'wait_time_minutes', 8)).reason, 'ml_rejected_input');
  assert.equal(fetch.mock.callCount(), 3);
});

test('network timeout produces fallback after a bounded retry', async (t) => {
  env(t, 'ML_SERVICE_URL', 'https://timeout.example');
  const fetch = t.mock.method(global, 'fetch', async () => { throw new DOMException('Timed out', 'TimeoutError'); });
  assert.equal((await ml.predict('/predict/queue-time', {}, 'wait_time_minutes', 19)).minutes, 19);
  assert.equal(fetch.mock.callCount(), 2);
});

test('routing uses longitude-latitude order and converts meters/seconds to km/minutes', async (t) => {
  env(t, 'OPENROUTESERVICE_API_KEY', 'test-key');
  const fetch = t.mock.method(global, 'fetch', async () => Response.json({ routes: [{ summary: { distance: 12500, duration: 1500 } }] }));
  const result = await travel.roadRoute({ longitude: 77.1, latitude: 28.1 }, { longitude: 77.2, latitude: 28.2 });
  assert.deepEqual(result, { distanceKm: 12.5, routeMinutes: 25 });
  assert.equal(fetch.mock.calls[0].arguments[0], 'https://api.heigit.org/openrouteservice/v2/directions/driving-car');
  assert.deepEqual(JSON.parse(fetch.mock.calls[0].arguments[1].body).coordinates, [[77.1, 28.1], [77.2, 28.2]]);
});

test('routing needs a key and does not invent straight-line travel when provider fails', async (t) => {
  env(t, 'OPENROUTESERVICE_API_KEY', undefined);
  const fetch = t.mock.method(global, 'fetch', async () => Response.json({}, { status: 403 }));
  const from = { longitude: 78, latitude: 29 };
  assert.equal((await travel.roadRoute(from, from)).reason, 'routing_not_configured');
  assert.equal(fetch.mock.callCount(), 0);
  process.env.OPENROUTESERVICE_API_KEY = 'test-key';
  assert.equal((await travel.roadRoute(from, from)).reason, 'routing_unavailable');
});

test('weather maps current rain and storm codes while rejecting unsupported snow and stale data', async (t) => {
  let code = 63;
  let time = Math.floor(Date.now() / 1000);
  t.mock.method(global, 'fetch', async () => Response.json({ current: { time, weather_code: code } }));
  assert.equal((await travel.pickupWeather({ latitude: 28.1, longitude: 77 })).severity, 1);
  code = 95;
  assert.equal((await travel.pickupWeather({ latitude: 28.2, longitude: 77 })).severity, 2);
  code = 73;
  assert.equal((await travel.pickupWeather({ latitude: 28.3, longitude: 77 })).reason, 'weather_unsupported');
  time -= 7200;
  assert.equal((await travel.pickupWeather({ latitude: 28.4, longitude: 77 })).reason, 'weather_stale');
});
