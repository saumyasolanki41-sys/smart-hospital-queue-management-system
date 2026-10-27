const mongoose = require('mongoose');
const connectDB = require('./src/config/db');
const Department = require('./src/models/Department');
const Doctor = require('./src/models/Doctor');
const directory = require('./data/hospital.json');

async function seedHospital() {
  await Promise.all([Department.init(), Doctor.init()]);
  return mongoose.connection.transaction(async (session) => {
    const result = { departmentsAdded: 0, departmentsReused: 0, doctorsAdded: 0, doctorsSkipped: 0 };
    for (const item of directory) {
      let department = await Department.findOne({ name: item.name }).collation({ locale: 'en', strength: 2 }).session(session);
      if (department) result.departmentsReused++;
      else {
        [department] = await Department.create([{ name: item.name, description: `${item.description}.` }], { session });
        result.departmentsAdded++;
      }
      for (const [index, name] of item.doctors.entries()) {
        const profile = { name: `Dr ${name}`, department: department._id, specialization: item.specialization,
          experienceYears: index === 0 ? 8 : 12, consultationFee: item.fee,
          averageConsultationMinutes: item.minutes, isAvailable: true };
        if (await Doctor.exists({ name: profile.name, department: department._id }).session(session)) {
          result.doctorsSkipped++;
          continue;
        }
        await Doctor.create([profile], { session });
        result.doctorsAdded++;
      }
    }
    return result;
  }, { readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' }, readPreference: 'primary' });
}

if (require.main === module) {
  (async () => {
    try {
      await connectDB();
      console.log(JSON.stringify(await seedHospital(), null, 2));
      console.log('Hospital directory ready. Existing records were preserved. No login accounts were created.');
    } catch {
      console.error('Hospital setup failed. Check database access and indexes; no directory transaction was committed.');
      process.exitCode = 1;
    } finally {
      await mongoose.disconnect();
    }
  })();
}

module.exports = seedHospital;
