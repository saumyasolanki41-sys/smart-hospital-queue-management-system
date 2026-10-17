# Authentication API: frontend and mobile handoff

Use this guide with `auth.postman_collection.json` in the same folder. Examples use
fake data. Replace email, passwords and OTPs with your own test account values.

## Base URL and access

Shared development API:

```text
https://smart-hospital-queue-management-system-production.up.railway.app
```

The supplied Postman collection defaults to this shared URL. Local developers can
change `baseUrl` to `http://localhost:5000`. Public health and missing/invalid-token
checks were verified on 2026-10-17. Login and email flows must also be tested
against this hosted URL before treating the full hosted authentication flow as verified.

Set one configurable API base URL in each client, without a trailing slash.

| Client location | Development base URL |
| --- | --- |
| Browser on the backend computer | `http://localhost:5000` |
| Android Studio standard emulator on the backend computer | `http://10.0.2.2:5000` |
| Physical phone or teammate computer on the same network | `http://BACKEND_COMPUTER_LAN_IP:5000` |
| Remote teammate over the internet | Shared deployed HTTPS URL, when available |

`localhost` always refers to the device running the client. Sharing a localhost
URL does not give another developer access to your backend. LAN use requires the
backend to be running, both devices on a reachable network, and port 5000 allowed
through the host firewall. Mobile platform network settings may also need to allow
local HTTP during development. Use HTTPS for a shared deployed environment.

To run a local backend from the repository root:

```powershell
npm.cmd --prefix backend install
npm.cmd --prefix backend start
```

Backend environment configuration is required. Keep the real `.env` on the server;
clients need the API base URL and public Google client configuration only.

Browser CORS currently allows exactly `FRONTEND_ORIGIN`, default
`http://localhost:5173`. Tell the backend developer the exact frontend origin
(scheme, host and port) if it differs, then restart the backend after configuration.
Native mobile HTTP calls are not subject to browser CORS; Flutter Web is.

## Endpoint overview

Every POST below uses `Content-Type: application/json`. Only `/me` needs the
application's Bearer access token. Do not send extra fields such as `role`.

| Method | Path | Success | Purpose |
| --- | --- | --- | --- |
| POST | `/api/auth/register` | 202 | Request registration OTP |
| POST | `/api/auth/register/verify` | 201 | Create verified patient account |
| POST | `/api/auth/login` | 202 | Check password and request login OTP |
| POST | `/api/auth/login/verify` | 200 | Verify login OTP and receive access token |
| POST | `/api/auth/google` | 200 | Exchange Google ID token for application access token |
| GET | `/api/auth/me` | 200 | Read current signed-in user |
| POST | `/api/auth/forgot-password` | 202 | Request password reset OTP |
| POST | `/api/auth/reset-password` | 200 | Set a new password using reset OTP |
| GET | `/api/health` | 200 | Check backend/database availability; 503 if disconnected |

## 1. Register

`POST /api/auth/register`

```json
{
  "name": "Test Patient",
  "email": "patient@example.com",
  "password": "TestPassword123!"
}
```

202 response:

```json
{
  "success": true,
  "data": {
    "message": "If registration can proceed, an OTP will be sent to your email."
  }
}
```

This generic response does not prove that an email was sent or that an account is
new. Display an OTP entry screen. Resend using this same endpoint after 60 seconds.

`POST /api/auth/register/verify`

```json
{ "email": "patient@example.com", "otp": "001234" }
```

201 response:

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

Registration does not issue a token. Navigate to login after success.

## 2. Password login

`POST /api/auth/login`

```json
{ "email": "patient@example.com", "password": "TestPassword123!" }
```

202 response:

```json
{
  "success": true,
  "data": {
    "challengeId": "507f1f77bcf86cd799439011",
    "message": "Login OTP sent. Verify it to complete login."
  }
}
```

Keep the actual `data.challengeId` from this response for the next request.
The user is not signed in yet. Resend by calling `/login` with the credentials
again after 60 seconds and keep the challenge ID from the latest response.

`POST /api/auth/login/verify`

```json
{ "challengeId": "507f1f77bcf86cd799439011", "otp": "001234" }
```

200 response:

```json
{
  "success": true,
  "data": {
    "accessToken": "APPLICATION_JWT",
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

Read `data.accessToken` and `data.user`. `expiresIn` is seconds: 900 = 15 minutes.

## 3. Google sign-in

Use the platform's Google sign-in integration to obtain a Google **ID token**, then
call `POST /api/auth/google`:

```json
{ "idToken": "GOOGLE_ID_TOKEN_FROM_SIGN_IN" }
```

The 200 response is identical to the password login verification response above.
Use the returned application `accessToken` for subsequent API requests.

The backend currently accepts ID tokens whose audience matches its
`GOOGLE_WEB_CLIENT_ID`. Web must use that public client ID. The mobile developer
must configure the native Google OAuth client(s) for the app and request an ID
token for the same backend web/server client ID. A native client ID as the token
audience will not pass the current backend verification. Coordinate this public
configuration with the backend developer; mobile Google integration is not yet
verified. Never put a Google client secret in the client app.

New Google accounts become patients. If the email already belongs to a separate
password account, the API returns 409 `ACCOUNT_LINK_REQUIRED`; show the original
login option. Account linking is not implemented. Google-only accounts use Google
sign-in rather than password login/reset. Non-Gmail identities without a verified
Workspace domain can return 403 `EMAIL_VERIFICATION_REQUIRED`; no additional
verification flow for these Google identities is implemented yet.

## 4. Read current user

`GET /api/auth/me`, without a body:

```text
Authorization: Bearer APPLICATION_JWT
```

200 response has the same `data.user` object shown in registration verification.
It does not issue a new token. Load this endpoint to check whether a saved session
is still usable. Roles come from the current database account. Client-side role
checks only control UI visibility; the backend enforces access.

## 5. Forgot/reset password

`POST /api/auth/forgot-password`

```json
{ "email": "patient@example.com" }
```

202 response:

```json
{
  "success": true,
  "data": {
    "message": "If this account supports password reset, an OTP will be sent to your email."
  }
}
```

This response is also used for unknown, unverified and Google-only accounts.
Resend through this endpoint after 60 seconds. Earlier requests during cooldown
return 202 without sending another email.

`POST /api/auth/reset-password`

```json
{
  "email": "patient@example.com",
  "otp": "001234",
  "newPassword": "NewPassword123!"
}
```

200 response:

```json
{
  "success": true,
  "data": {
    "message": "Password reset successful. Log in with your new password."
  }
}
```

Clear the client's old session and navigate to login. The old password, previous
access tokens and pending login OTP challenges are invalidated. No token is
returned by password reset.

## Validation, OTPs and errors

- Registration name: 2–100 characters after trimming.
- Email: valid address, up to 254 characters; normalized to lowercase.
- New passwords: at least 8 characters, at most 72 UTF-8 bytes. Passwords are not trimmed.
- OTP: exactly six digits as a string, including leading zeroes.
- OTP expiry: five minutes; maximum five wrong attempts per challenge.
- Registration, login and password reset OTPs are separate. Always use the latest
  OTP for the corresponding flow. Successful verification consumes it.
- Never assume 202 means the user is authenticated; only successful login/Google
  responses issue an application access token.

All API errors have this shape:

```json
{
  "success": false,
  "error": { "code": "VALIDATION_ERROR", "message": "Human-readable explanation" }
}
```

| HTTP | Code | Client action |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR`, `INVALID_INPUT`, `INVALID_JSON` | Correct request fields/types/JSON |
| 400 | `INVALID_OR_EXPIRED_OTP` | Show OTP error; offer a fresh request after cooldown |
| 401 | `INVALID_CREDENTIALS` | Show email/password error |
| 401 | `INVALID_GOOGLE_TOKEN` | Restart Google sign-in |
| 401 | `UNAUTHORIZED` | Clear application session and return to login |
| 403 | `FORBIDDEN` | Show access denied |
| 403 | `EMAIL_VERIFICATION_REQUIRED` | Offer another supported sign-in method |
| 409 | `ACCOUNT_EXISTS`, `ACCOUNT_LINK_REQUIRED` | Offer existing sign-in method |
| 429 | `REGISTRATION_COOLDOWN`, `LOGIN_COOLDOWN` | Wait 60 seconds; these return `Retry-After: 60` |
| 429 | `RATE_LIMITED` | Stop automatic retries and show a retry-later message |
| 503 | `EMAIL_UNAVAILABLE` | Show temporary delivery failure; retry later |
| 500 | `INTERNAL_ERROR` | Show temporary backend failure |

Limits per IP per 15 minutes: registration 10, registration verification 30,
password login 10, login verification 30, Google login 20. Forgot/reset endpoints
share a combined limit of 10. Avoid repeatedly retrying failed requests.

Tokens last 15 minutes. There is no refresh-token or server logout endpoint yet.
For logout, clear the client session; this does not revoke a copied token on the
server. On token expiry, ask the user to sign in again. Keep tokens out of logs,
URLs, screenshots and shared Postman exports. Use platform-appropriate protected
storage for native apps; the web client can keep the token in memory. This API
uses the Authorization header, not an authentication cookie.

## Postman collection

1. Import `docs/auth.postman_collection.json`.
2. Open the collection's Variables and set `baseUrl`, `email`, `password`, `name`.
3. Run Register, then set `otp` from the registration email and run Verify registration.
4. Run Login. Its script saves the response's `challengeId` automatically.
5. Replace `otp` with the login email OTP and run Verify login. Its script saves
   `accessToken` automatically. Run Current user to use it.
6. For Google, set `googleIdToken` from a fresh Google sign-in and run Google login.
7. For reset, run Forgot password, set the new reset `otp` and `newPassword`, then
   run Reset password. On success the script clears `accessToken`; update the
   `password` variable to the new password before the next Login request.

Use your own local variable values. Before exporting/sharing a used collection,
clear passwords, OTPs, tokens and account information. The supplied file contains
only example values and empty token fields. These requests are interactive: do
not run the full collection automatically without entering each newly emailed OTP.
