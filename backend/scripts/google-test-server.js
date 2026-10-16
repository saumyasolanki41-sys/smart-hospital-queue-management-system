const express = require('express');
const path = require('node:path');

const clientId = process.env.GOOGLE_WEB_CLIENT_ID?.trim();

if (!clientId || !/^[\w-]+\.apps\.googleusercontent\.com$/.test(clientId)) {
  throw new Error('Configure GOOGLE_WEB_CLIENT_ID in your local .env.');
}

const app = express();

app.disable('x-powered-by');

app.use((req, res, next) => {
  res.set('Cache-Control', 'no-store');
  res.set('Cross-Origin-Opener-Policy', 'same-origin-allow-popups');
  next();
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'google-test.html'));
});

app.get('/config', (req, res) => {
  // Client ID public hoti hai. Koi secret return nahi hota.
  res.json({ clientId });
});

const server = app.listen(5173, '127.0.0.1', () => {
  console.log('Google test page: http://localhost:5173');
});

server.on('error', () => {
  console.error('Test server could not start. Check whether port 5173 is in use.');
  process.exitCode = 1;
});