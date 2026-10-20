const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');

const previousOrigin = process.env.FRONTEND_ORIGIN;
process.env.FRONTEND_ORIGIN = ' http://localhost:5173, https://smart-hospital-queue-managment-syst.vercel.app, ';
const app = require('../src/app');
if (previousOrigin === undefined) delete process.env.FRONTEND_ORIGIN;
else process.env.FRONTEND_ORIGIN = previousOrigin;

let server;
let base;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => new Promise(resolve => server.close(resolve)));

function preflight(origin) {
  return fetch(`${base}/api/auth/google`, { method: 'OPTIONS', headers: {
    Origin: origin,
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type,authorization',
  } });
}

test('Google login preflight supports local and deployed frontend with exact origin reflection', async () => {
  for (const origin of ['http://localhost:5173', 'https://smart-hospital-queue-managment-syst.vercel.app']) {
    const response = await preflight(origin);
    assert.equal(response.status, 204);
    assert.equal(response.headers.get('access-control-allow-origin'), origin);
    assert.match(response.headers.get('access-control-allow-methods'), /POST/);
    assert.match(response.headers.get('access-control-allow-headers'), /Authorization/i);
    assert.match(response.headers.get('vary'), /Origin/);
  }
});

test('CORS does not allow unrelated origins or domains that append text to an allowed origin', async () => {
  for (const origin of ['https://example.com', 'http://localhost:5174',
    'https://smart-hospital-queue-managment-syst.vercel.app.attacker.example']) {
    const response = await preflight(origin);
    assert.equal(response.headers.get('access-control-allow-origin'), null);
  }
});

test('public reads allow the configured browser origin and preserve requests without Origin', async () => {
  const origin = 'http://localhost:5173';
  const response = await fetch(`${base}/api/unknown`, { headers: { Origin: origin } });
  assert.equal(response.status, 404);
  assert.equal(response.headers.get('access-control-allow-origin'), origin);
  const nativeResponse = await fetch(`${base}/api/unknown`);
  assert.equal(nativeResponse.status, 404);
  assert.equal(nativeResponse.headers.get('access-control-allow-origin'), null);
});
