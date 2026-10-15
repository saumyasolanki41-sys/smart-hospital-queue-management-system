const createMailTransport = require('../src/config/mail');

async function sendTestMail() {
  let transporter;

  try {
    transporter = createMailTransport();

    const result = await transporter.sendMail({
      from: process.env.SMTP_USER.trim(),
      to: process.env.SMTP_USER.trim(),
      subject: 'Hospital Backend - Email Test',
      text: 'Gmail email sending test successful. Yeh OTP nahi hai.',
    });

    if (!result.accepted || result.accepted.length === 0) {
      throw new Error('Email was not accepted.');
    }

    console.log('Test email accepted by Gmail. Inbox aur Spam check karo.');
  } catch(error) {
   console.error({
  code: error.code,
  command: error.command,
  responseCode: error.responseCode,
});
    process.exitCode = 1;
  } finally {
    if (transporter) transporter.close();
  }
}

sendTestMail();