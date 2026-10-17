# Shared authentication backend

The backend supports Gmail SMTP locally and Brevo HTTPS email for hosts that block
SMTP. Client API paths and JSON responses stay the same.

## Brevo setup

1. Create a Brevo account and complete any account activation requirements.
2. Add and verify a sender email in the senders settings. Use that exact address
   for `BREVO_SENDER_EMAIL`. A domain you control can be authenticated for delivery;
   free email provider domains cannot. Brevo may rewrite free sender addresses.
3. Generate an API key in SMTP & API > API Keys. Use an API key, not an SMTP key.
4. Store the key in the hosting service's secret variables, not Git or chat.

Brevo's free plan currently includes 300 daily email sends. Provider acceptance
does not guarantee inbox delivery. Check delivery logs and Spam when testing.

Sources: [Sending API](https://developers.brevo.com/docs/send-a-transactional-email),
[API keys](https://developers.brevo.com/docs/api-key-authentication),
[free plan](https://help.brevo.com/hc/en-us/articles/208589409-About-Brevo-s-pricing-plans),
[sender authentication](https://help.brevo.com/hc/en-us/articles/16045394674066-Troubleshooting-Domain-authentication).

## Hosting configuration

| Setting | Value |
| --- | --- |
| Repository | `saumyasolanki41-sys/smart-hospital-queue-management-system` |
| Branch | `backend` |
| Root directory | `backend` |
| Runtime | Node.js 22 or newer |
| Install command | `npm ci` |
| Start command | `npm run start:prod` |
| Healthcheck path | `/api/health` |

`start:prod` uses environment variables supplied by hosting and does not require
a physical `.env` file. Keep `npm start` for local development with `.env`.
The application already reads the host-provided `PORT` and handles SIGTERM.

Required hosting variables:

```text
NODE_ENV=production
EMAIL_PROVIDER=brevo
BREVO_API_KEY=YOUR_PRIVATE_API_KEY
BREVO_SENDER_EMAIL=YOUR_VERIFIED_SENDER
MONGODB_URI=YOUR_PRIVATE_ATLAS_CONNECTION_STRING
OTP_HASH_SECRET=YOUR_64_CHARACTER_HEXADECIMAL_SECRET
JWT_SECRET=YOUR_64_CHARACTER_HEXADECIMAL_SECRET
GOOGLE_WEB_CLIENT_ID=YOUR_PUBLIC_GOOGLE_WEB_CLIENT_ID
FRONTEND_ORIGIN=http://localhost:5173
```

Replace placeholders privately in hosting settings. Do not set a fixed PORT when
the host supplies one. SMTP_USER/SMTP_PASS are not required for the Brevo path.
Set FRONTEND_ORIGIN to the frontend developer's exact browser origin. The current
code supports one origin; coordinate if multiple browser origins are needed.
Ensure Atlas network access permits the hosting service's outbound connection.
An isolated development database/account is preferable for shared testing.

Railway Free/Trial/Hobby block SMTP, so use the HTTPS email path there. Railway
hosting has its own plan/credit limits; a free email plan does not make hosting
permanently free. Check the account's current allowance before deployment.
[Railway outbound networking](https://docs.railway.com/networking/outbound-networking)

For a reverse proxy, verify rate-limit behavior before exposing the shared URL.
The app has no explicit trusted proxy configuration; do not blindly trust all
forwarded IP headers. Current limits are in memory, so use one instance for this
development setup. Multi-instance deployment needs a shared rate-limit store.

## Checks before sharing the URL

1. Commit/push the intended source changes when authorized, then deploy that revision.
2. Generate a public HTTPS domain and open `/api/health`; require HTTP 200.
3. With your own test address, exercise registration, login OTP and password reset.
   Confirm actual email delivery, not just API acceptance.
4. Test Google login, then GET `/api/auth/me` with the returned application token.
5. Verify invalid/expired tokens are rejected and browser requests pass CORS.
6. Give teammates the HTTPS base URL. Update the Postman collection's `baseUrl`.

No live deployment or Brevo delivery has been verified yet. The standalone
`check-mail.js` and `send-test-mail.js` scripts test Gmail SMTP only; use the API
flows to verify Brevo integration.
