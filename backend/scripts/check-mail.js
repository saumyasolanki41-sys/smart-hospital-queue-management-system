const createMailTransport = require('../src/config/mail');

async function checkMail() {
  let transporter;

  try {
    transporter = createMailTransport();
    await transporter.verify();

    console.log('Gmail SMTP connection successful.');
  } catch {
    console.error(
      'Gmail connection failed. SMTP_USER, App Password aur network check karo.'
    );
    process.exitCode = 1;
  } finally {
    if (transporter) transporter.close();
  }
}

checkMail();