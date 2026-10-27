# Password and email OTP login

Backend scope, review fixes and remaining verification are in [BACKEND-REVIEW.md](BACKEND-REVIEW.md).
Existing accounts can explicitly link matching Google identities after login;
see the linking flow in [AUTH-INTEGRATION.md](AUTH-INTEGRATION.md).
ML setup, prediction sources and fallback behavior are in [ML-INTEGRATION.md](ML-INTEGRATION.md).

Department and doctor endpoints are documented in [HOSPITAL-API.md](HOSPITAL-API.md).
Patient queue tokens are documented in [QUEUE-API.md](QUEUE-API.md).
Staff queue management is documented in [STAFF-QUEUE-API.md](STAFF-QUEUE-API.md).
Staff dashboard counts are documented in [DASHBOARD-API.md](DASHBOARD-API.md).
Doctor dashboard counts are documented in [DOCTOR-DASHBOARD-API.md](DOCTOR-DASHBOARD-API.md).
Ambulance records and location are documented in [AMBULANCE-API.md](AMBULANCE-API.md).
Patient transport and staff assignments are documented in [AMBULANCE-REQUEST-API.md](AMBULANCE-REQUEST-API.md).

For the complete frontend/mobile handoff, including registration, Google sign-in,
network setup and importable Postman requests, see [AUTH-INTEGRATION.md](AUTH-INTEGRATION.md)
and [auth.postman_collection.json](auth.postman_collection.json).

Current local API base: `http://localhost:8080` with `PORT=8080` in the local `.env`.
The code and `.env.example` default to 8080; always match the port printed by your server.
Send JSON with `Content-Type: application/json`.
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
used; it remains separate from the OTP HMAC secret. Private routes use the
authentication middleware described below. No refresh token is issued.

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
npm.cmd --prefix backend run check
npm.cmd --prefix backend audit
npm.cmd --prefix backend start
```

The automated test folder was removed at the project owner's request. Use the
Postman collection for manual API checks. Syntax checking does not replace
functional verification. Live Atlas/email delivery and simultaneous transaction
behavior require integration checks against isolated test accounts.
The new LoginChallenge model initializes a collection and unique/TTL indexes when
the running app connects; existing User/PendingRegistration schemas are unchanged.

## GET /api/auth/me

Protected profile endpoint. No request body. Use the application's `accessToken`
from successful Google login or password + OTP verification:

```text
Authorization: Bearer YOUR_ACCESS_TOKEN
```

In Postman, select Authorization > Bearer Token and paste only the token value.
The Google ID token, OAuth client ID, OTP and challenge ID are not API access tokens.

HTTP 200:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439012",
      "name": "Test Patient",
      "email": "patient@example.com",
      "role": "patient"
    }
  }
}
```

Each protected request verifies HS256 signature, issuer, audience, expiry and a
maximum token age of 15 minutes. An expiry claim, issued-at time and valid MongoDB
user ID subject are required. Only the Authorization header is accepted; query
parameters and cookies are ignored. Invalid/missing/expired tokens return:

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "A valid login token is required."
  }
}
```

HTTP status is 401 with `WWW-Authenticate: Bearer`. Missing/deleted users,
unverified accounts and unknown database roles also return 401. Database/config
failures return the existing generic 500 response. Profile and authorization
responses use `Cache-Control: no-store`.

The middleware reads the user and current role from MongoDB on every request and
attaches only `{ id, name, email, role }` to `req.user`. It never trusts a role from
token claims, request bodies, query parameters or custom headers. Role changes
therefore apply to the next protected request without reissuing the token.

## Protecting staff and patient routes

Import `authenticate` and `allowRoles` from `src/middleware/auth.middleware.js`.
Place `authenticate` first, then the explicit role list, then the controller:

```javascript
router.post('/call-next', authenticate, allowRoles('doctor', 'receptionist', 'admin'), callNext);
```

This is a usage example for future queue routes, not an implemented endpoint.
Supported roles are `patient`, `doctor`, `receptionist` and `admin`. Empty/unknown
role configuration throws during route setup. Admin is allowed only when explicitly
listed; there is no automatic role hierarchy. An authenticated user outside the
allowed list receives HTTP 403 with `FORBIDDEN`. Missing authentication receives
401. Patient resource ownership checks will be added with the patient APIs; role
checks alone do not enforce ownership. Public registration still cannot assign
staff roles. No user schema or role provisioning endpoint was changed.

There is currently no logout denylist or refresh token. Password reset increments
the user's `tokenVersion`, which invalidates previously issued tokens on protected
routes. Existing accounts and legacy tokens without a version use version zero;
no manual backfill is needed. New Google and password logins include the current
version. Keep access tokens private and send them only over HTTPS in production.

## Forgot password

`POST /api/auth/forgot-password`

```json
{ "email": "patient@example.com" }
```

Returns 202 with a generic `data.message`. Unknown, unverified and Google-only
accounts receive the same response without an email. Existing verified password
accounts receive a six-digit password reset OTP. Resending within 60 seconds
returns the same accepted response without sending another email. The OTP expires
after five minutes. A successful resend replaces the previous OTP. Mail failure
returns 503 `EMAIL_UNAVAILABLE` and removes only the failed challenge version.

## Reset password

`POST /api/auth/reset-password`

```json
{
  "email": "patient@example.com",
  "otp": "001234",
  "newPassword": "NewPassword123!"
}
```

Passwords require at least eight characters and at most 72 UTF-8 bytes. OTPs must
be six-digit strings. Additional fields are rejected. Invalid input returns 400
`VALIDATION_ERROR`. Invalid, expired, reused or exhausted OTPs return 400
`INVALID_OR_EXPIRED_OTP`. Five incorrect OTP attempts lock that challenge.

Successful reset returns 200 with `data.message`, without a login token. The
transaction consumes the OTP, saves a bcrypt hash, increments `tokenVersion` and
deletes pending login challenges. Log in again with the new password. Existing
account names, roles and Google identities are preserved. A Google-only account
cannot acquire a password through this endpoint.

Both reset endpoints share an IP limit of 10 requests per 15 minutes, returning
429 `RATE_LIMITED` when exceeded. Responses use `Cache-Control: no-store`.
These limits are in memory and require shared storage for multiple server instances.
Transactions require a replica set such as Atlas. Automated tests mock database
transactions; real concurrent transaction behavior has not been independently tested.
