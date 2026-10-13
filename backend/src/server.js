const express = require('express');
const mongoose = require('mongoose');
const connectDB = require('./config/db');

const app = express();

app.disable('x-powered-by');
app.use(express.json({ limit: '16kb' }));

app.get('/api/health', (req, res) => {
  const connected = mongoose.connection.readyState === 1;

  if (!connected) {
    return res.status(503).json({
      success: false,
      error: {
        code: 'SERVICE_UNAVAILABLE',
        message: 'Database is unavailable.',
      },
    });
  }

  return res.status(200).json({
    success: true,
    data: {
      status: 'ok',
      database: 'connected',
    },
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'Route not found.',
    },
  });
});

app.use((err, req, res, next) => {
  if (res.headersSent) return next(err);

  let status = 500;
  let code = 'INTERNAL_ERROR';
  let message = 'An unexpected error occurred.';

  if (err.type === 'entity.parse.failed') {
    status = 400;
    code = 'INVALID_JSON';
    message = 'Request body must contain valid JSON.';
  } else if (err.type === 'entity.too.large') {
    status = 413;
    code = 'BODY_TOO_LARGE';
    message = 'Request body exceeds the size limit.';
  }

  res.status(status).json({
    success: false,
    error: { code, message },
  });
});

async function startServer() {
  const port = Number(process.env.PORT ?? 5000);

  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }

  await connectDB();

  const server = app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
  });

  server.on('error', () => {
    console.error('Server could not start. Check whether PORT is already in use.');
    mongoose.disconnect().catch(() => {
      console.error('Database disconnect failed.');
    });
    process.exitCode = 1;
  });
    let stopping = false;

  function stopServer() {
    if (stopping) return;
    stopping = true;

    console.log('Server closing...');

    // Shutdown atak jaye toh 10 seconds baad exit.
    const timer = setTimeout(() => {
      console.error('Shutdown timed out.');
      process.exit(1);
    }, 10000);

    timer.unref();

    server.close(async () => {
      try {
        await mongoose.disconnect();
        console.log('Server and database closed.');
      } catch {
        console.error('Database disconnect failed.');
        process.exitCode = 1;
      } finally {
        clearTimeout(timer);
      }
    });
  }

  process.once('SIGINT', stopServer);
  process.once('SIGTERM', stopServer);
}

startServer().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});