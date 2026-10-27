const mongoose = require('mongoose');

async function connectDB() {
  const uri = process.env.MONGODB_URI?.trim();

  if (!uri) {
    throw new Error('MONGODB_URI missing hai. Local .env check karo.');
  }

  try {
    await mongoose.connect(uri, {
      dbName: 'hospital_queue',
      serverSelectionTimeoutMS: 10000,
    });

    console.log('MongoDB Atlas connected: hospital_queue');
  } catch {
    throw new Error(
      'Atlas connection failed. URI, database username/password aur IP access list check karo.'
    );
  }
}

module.exports = connectDB;

if (require.main === module) {
  (async () => {
    try {
      await connectDB();
    } catch (error) {
      console.error(error.message);
      process.exitCode = 1;
    } finally {
      await mongoose.disconnect();
    }
  })();
}