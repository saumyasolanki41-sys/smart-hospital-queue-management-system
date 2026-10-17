# Password and email OTP login

Local API base: `http://localhost:5000`. Send JSON with `Content-Type: application/json`.
Production clients must use HTTPS. OTPs, passwords and tokens must never be logged.

## POST /api/auth/login

Requires an existing email/password account with verified email. Google-only accounts
use the existing Google sign-in endpoint. The password is checked with bcrypt before
any OTP is stored or sent. Email is trimmed and lowercased; passwords are not trimmed.

Request:

```json
{ "email": "patient@example.com", "password": "YOUR_PASSWORD" }
```

HTTP 202:

```json
{
  "success": true,
  "data": {
    "challengeId": "24-character MongoDB object ID",
    "message": "Login OTP sent. Verify it to complete login."
  }
}
```

This response does not authenticate the caller or contain a JWT. Keep `challengeId`
for the verification request. Resend by submitting the email/password again after
60 seconds; use the latest emailed OTP. Each challenge expires five minutes after
generation. The previous version is replaced on resend. Do not use registration OTPs.

## POST /api/auth/login/verify

Request (OTP is a string so leading zeroes are retained):

```json
{ "challengeId": "507f1f77bcf86cd799439011", "otp": "001234" }
```

HTTP 200:

```json
{
  "success": true,
  "data": {
    "accessToken": "JWT",
    "tokenType": "Bearer",
    "expiresIn": 900,
    "user": {
      "id": "507f1f77bcf86cd799439012",
      "name": "Test Patient",
      "email": "patient@example.com",
      "role": "patient"
    }
  }
}
```

The JWT uses HS256, subject=user ID, issuer=`hospital-queue-api`,
audience=`hospital-queue-clients`, and a 15-minute expiry. The existing JWT secret is
used; it remains separate from the OTP HMAC secret. Private routes still require
JWT authentication middleware (the next feature). No refresh token is issued.

OTP verification uses a MongoDB transaction with majority write concern. Failed
attempts commit before returning an error. Five wrong six-digit submissions exhaust
that challenge; malformed input is rejected before database access. Expired, absent,
used and exhausted challenges share an error. Successful consumption and token
creation run within the transaction; its result is returned only after commit.
Missing/unverified users and changed passwords cannot complete the challenge.
TTL deletion is cleanup only; expiry is explicitly checked on every verification.

## Errors

Errors use `{ "success": false, "error": { "code": "...", "message": "..." } }`.

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Invalid fields, types, email, password size, challenge ID or OTP format |
| 400 | INVALID_OR_EXPIRED_OTP | Wrong, expired, used or exhausted OTP; or account no longer eligible |
| 401 | INVALID_CREDENTIALS | Generic error for unknown, wrong-password, unverified and Google-only accounts |
| 429 | LOGIN_COOLDOWN | Wait 60 seconds; `Retry-After: 60` |
| 429 | RATE_LIMITED | IP request quota reached |
| 503 | EMAIL_UNAVAILABLE | Delivery failed; only that issued challenge version is cleaned up |
| 500 | INTERNAL_ERROR | Unexpected errors; internal details remain hidden |

The request endpoint allows 10 requests/IP/15 minutes; verification allows 30.
All attempts, including successful ones, count. Responses use `Cache-Control: no-store`.
Current IP counters are process-local and reset on restart. Multiple production
instances need a shared rate-limit store and correct trusted-proxy configuration.

## Verification and limits

From the repository root on Windows:

```powershell
npm.cmd --prefix backend test
npm.cmd --prefix backend run check
npm.cmd --prefix backend audit
npm.cmd --prefix backend start
```

Tests cover service decisions with mocked database/SMTP, a real bcrypt comparison,
JWT signature/claims, and HTTP routing/errors/rate limits on an ephemeral local port.
They do not send email or modify Atlas. Live Atlas/SMTP delivery and simultaneous
transaction rollback/consumption require an integration check against a test account.
The new LoginChallenge model initializes a collection and unique/TTL indexes when
the running app connects; existing User/PendingRegistration schemas are unchanged.
