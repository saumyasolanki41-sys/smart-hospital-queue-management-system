const mongoose = require('mongoose');
const connectDB = require('./config/db');
const app = require('./app');

async function startServer() {
  const { port } = require('./config/env');
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