# Smart Hospital Queue Management System

**Live website:** [Open Smart Hospital](https://smart-hospital-queue-managment-syst.vercel.app/)

A hospital queue management project with a React website, Flutter mobile app,
shared Node.js backend, and external prediction service. Patients can find doctors,
join same-day queues, track tokens and estimated waits, and request an ambulance.
Doctors and staff manage queues and transport requests through authorized APIs.

> The current system issues same-day queue tokens. It does not reserve appointment
> time slots. Waiting times and ambulance ETAs are estimates, not guarantees.

## Repository branches

Component code lives in separate branches with different directory layouts.

| Branch | Component |
| --- | --- |
| [backend](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/tree/backend) | Express API, database models, directory loader and integration docs |
| [frontend](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/tree/frontend) | React web application |
| [appdev](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/tree/appdev) | Flutter mobile application |
| [ML](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/tree/ML) | Prediction service source |
| design | Design work |
| main | Project overview and final documentation entry point |

Backend paths and relative documentation links below refer to the `backend` branch.
Use separate checkouts or worktrees for components; do not switch branches over
uncommitted work.

## Features

- Email/password registration and login with email OTP verification.
- Google ID-token authentication and explicit existing-account linking.
- Password reset for password-based accounts.
- Role authorization, ownership checks, input validation and rate limiting.
- Department and doctor directory, availability and doctor account/profile linking.
- Daily doctor-specific queue numbering, transactional booking and duplicate protection.
- Patient token listing, status, waiting estimates and waiting-token cancellation.
- Staff queue listing, call-next, consultation completion and skipping.
- Staff/admin and linked-doctor dashboards.
- Ambulance inventory, location updates, requests, assignment and ETA lookup.
- ML integration with queue/routing fallbacks when applicable.

Backend support does not imply every client screen is integrated. Review and test
the relevant client branch before a demonstration or release.

## Technology stack

| Layer | Technologies |
| --- | --- |
| Web | React, Vite, Tailwind CSS, Axios, React Router, Three.js / React Three Fiber |
| Mobile | Flutter, Provider, HTTP client, secure storage, Google Sign-In |
| Backend | Node.js, Express, Mongoose |
| Database | MongoDB Atlas |
| Authentication | bcrypt, JSON Web Tokens, Google Auth Library |
| Email | Gmail SMTP through Nodemailer or Brevo HTTPS API |
| Routing and weather | OpenRouteService and Open-Meteo |
| Prediction | External queue waiting-time and ambulance ETA API |

The backend verifies Google ID tokens directly and issues its own JWTs. Its
authentication flow does not use Firebase Authentication.

## Architecture

```mermaid
flowchart LR
    Web[React web client] --> API[Express backend]
    App[Flutter mobile app] --> API
    API --> DB[(MongoDB Atlas)]
    API --> Google[Google token verification]
    API --> Email[Brevo or Gmail SMTP]
    API --> ML[Prediction service]
    API --> Routing[OpenRouteService]
    API --> Weather[Open-Meteo]
```

Requests pass through routes, authentication/authorization middleware, controllers,
services and database models. Private credentials stay on the backend.

## Backend setup

### Prerequisites

- Node.js 22 or newer and npm.
- MongoDB Atlas or a MongoDB replica set supporting transactions.
- An email provider for OTP delivery.
- A Google OAuth Web Client ID for Google sign-in.

From PowerShell:

```powershell
git clone --branch backend https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system.git
cd smart-hospital-queue-management-system
npm.cmd --prefix backend ci
Copy-Item backend/.env.example backend/.env
```

Configure `backend/.env` privately:

| Variable | Purpose |
| --- | --- |
| PORT | Local port; defaults to 8080 |
| MONGODB_URI | Private database URI; server uses database hospital_queue |
| JWT_SECRET | Independent 64-character hexadecimal signing secret |
| OTP_HASH_SECRET | Independent 64-character hexadecimal hashing secret |
| EMAIL_PROVIDER | smtp or brevo |
| SMTP_USER, SMTP_PASS | Gmail sender and App Password for SMTP mode |
| BREVO_API_KEY, BREVO_SENDER_EMAIL | API key and verified sender for Brevo mode |
| GOOGLE_WEB_CLIENT_ID | Public Web OAuth Client ID expected by token verification |
| FRONTEND_ORIGIN | Comma-separated exact allowed browser origins |
| ML_SERVICE_URL | Prediction service base URL |
| OPENROUTESERVICE_API_KEY | Private routing API key |

Generate the two secrets separately by running this command twice:

```powershell
node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"
```

Keep the results private. Never commit `.env`. Open-Meteo needs no key for the
current integration.

Start the server from the repository root:

```powershell
npm.cmd --prefix backend start
```

For automatic restart during development:

```powershell
npm.cmd --prefix backend run dev
```

Open `http://localhost:8080/api/health`. A healthy response is:

```json
{"success":true,"data":{"status":"ok","database":"connected"}}
```

### Hospital directory

```powershell
npm.cmd --prefix backend run seed:hospital
```

The dataset includes 24 departments and 48 fictional doctor profiles. The loader
preserves existing records and skips matches; actual totals depend on existing data.
Profiles do not create doctor login accounts. See [Hospital directory](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/HOSPITAL-DIRECTORY.md).

## Web and mobile setup

Clone the web component separately:

```powershell
git clone --branch frontend https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system.git smart-hospital-web
cd smart-hospital-web
npm ci
Copy-Item .env.example .env
```

Configure the web environment:

```dotenv
VITE_API_BASE_URL=http://localhost:8080
VITE_GOOGLE_CLIENT_ID=YOUR_PUBLIC_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com
```

Run `npm run dev` locally or `npm run build` for production. Hosted builds must use
the deployed backend URL rather than localhost.

On `appdev`, use a Flutter SDK compatible with that branch's `pubspec.yaml`, run
`flutter pub get`, configure the API URL and Google sign-in, then run `flutter run`.
A phone's localhost is not the backend computer. Android OAuth must match the app's
package name and actual signing-certificate SHA-1. Flutter's `serverClientId` must
match the backend Web Client ID.

The `ML` branch has its own dependencies in `ml/requirements.txt`. Coordinate its
API contract and deployment with the backend team.

## Authentication and roles

| Role | Access |
| --- | --- |
| patient | Own queue tokens and ambulance requests |
| doctor | Dashboard and queue for the linked doctor profile |
| receptionist | Staff dashboard, queues and ambulance operations |
| admin | Directory management and authorized staff operations |

Public registration creates patients. A client role selector does not grant
permissions. Provision privileged roles through a trusted administrative process.
Doctor access also requires a verified doctor account linked to a doctor profile.

Registration and password login each require their own OTP verification step.
Access tokens expire after 15 minutes; no refresh-token feature is currently provided.
Protected requests send `Authorization: Bearer BACKEND_ACCESS_TOKEN`.

Google login uses `POST /api/auth/google` with only an `idToken` field. If the email
already belongs to an unlinked account, log in through its original method, then
call `POST /api/auth/google/link` with the backend Bearer token and a fresh Google
ID token for the same email. The returned backend access token, not the Google ID
token, authorizes subsequent API requests.

## API overview

The backend defines **37 method-and-route endpoints**, including health. External
ML service endpoints are not part of this count.

| Module | Prefix | Count | Documentation |
| --- | --- | ---: | --- |
| Authentication | /api/auth | 9 | [Authentication](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/AUTH-INTEGRATION.md) |
| Directory | /api/departments and /api/doctors | 6 | [Hospital API](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/HOSPITAL-API.md) |
| Patient queue | /api/queue | 4 | [Queue API](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/QUEUE-API.md) |
| Staff queue | /api/staff/queues | 4 | [Staff queue](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/STAFF-QUEUE-API.md) |
| Dashboards | /api/staff/dashboard and /api/doctor/dashboard | 2 | [Staff](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/DASHBOARD-API.md), [Doctor](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/DOCTOR-DASHBOARD-API.md) |
| Ambulance inventory | /api/ambulances | 4 | [Inventory API](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/AMBULANCE-API.md) |
| Ambulance requests and ETA | /api/ambulance-requests | 7 | [Request API](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/AMBULANCE-REQUEST-API.md) |
| Health | /api/health | 1 | [API guide](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/API.md) |

### Queue behavior

```text
waiting -> called -> completed
                 -> skipped
waiting -> cancelled
```

Book with `POST /api/queue/tokens` and JSON containing only `doctorId`.

- Numbers increment separately for each doctor and India calendar date (UTC+05:30).
- Only one active token per patient, doctor and date is allowed. Cancelled numbers
  are not reused.
- Counter increment and token creation share a transaction; unique indexes protect
  numbering and duplicate active bookings.
- People ahead counts lower-numbered waiting tokens. The current called
  consultation contributes remaining time separately.
- Booking and status return `peopleAhead` and `estimatedWaitMinutes` alongside
  `data.token`, not inside it.
- `/api/queue/tokens/mine` is a paginated list. Fetch `/api/queue/tokens/:id` for the
  selected token's live estimate.
- Numeric zero is valid. Null means unavailable/not applicable. Called, completed,
  cancelled, skipped and historical tokens do not have waiting estimates.
- Populated doctor details include department ID and name. Handle plain doctor IDs
  in booking fallback/cancellation responses and null removed references.

See [Queue API](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/QUEUE-API.md) for complete response examples and the behavior
when estimation fails after a booking has already committed.

## Deployment

| Component | Platform |
| --- | --- |
| Backend | Railway |
| Web frontend | Vercel |
| Database | MongoDB Atlas |
| Current configured ML service | Vercel; previously Render |
| Email | Brevo or Gmail SMTP |
| OAuth configuration | Google Cloud Console |

Configured addresses:

- Backend: https://smart-hospital-queue-management-system-production.up.railway.app
- Web: https://smart-hospital-queue-managment-syst.vercel.app
- ML: https://smart-hospital-queue-management-sys-ten.vercel.app

These addresses are deployment references, not a guarantee of current service
health. Verify the deployed revision and environment variables when troubleshooting.

Railway configuration: branch `backend`, root `backend`, install `npm ci`, start
`npm run start:prod`, health check `/api/health`. Store secrets in Railway Variables.
Production startup uses hosting variables rather than a checked-in `.env` file.
See [Deployment guide](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/DEPLOYMENT.md).

Configure browser origins separately in backend CORS and Google OAuth. Native
mobile HTTP requests do not use browser CORS. Email acceptance does not guarantee
inbox delivery; inspect email provider logs if OTP delivery is delayed.

## Verification

```powershell
npm.cmd --prefix backend run check
```

This checks syntax in `app.js` and `server.js`, not every API end to end. The backend
test suite was removed and no `npm test` script is currently defined.

Use [API documentation](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/API.md) and the [authentication Postman collection](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/auth.postman_collection.json)
for manual checks. Verify OTP delivery, role/ownership boundaries, duplicate booking,
numbering, queue transitions, estimates, and ambulance assignment/release. Use isolated
records and remove them afterwards. Never share authentication tokens in bug reports.

## Integration guides

- [ML integration](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/ML-INTEGRATION.md)
- [Frontend handoff](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/FRONTEND-INTEGRATION-GUIDE.docx)
- [Mobile handoff](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/MOBILE-APP-INTEGRATION-GUIDE.docx)
- [Backend review](https://github.com/saumyasolanki41-sys/smart-hospital-queue-management-system/blob/backend/docs/BACKEND-REVIEW.md)

## Current limitations

- No reserved appointment slots, future-day scheduling or payments.
- No refresh-token sessions or Google-only account password-creation flow.
- ML supports specific inputs/specialties; clients must handle fallback/unavailable results.
- Ambulance ETA needs assignment, fresh location data and external services.
  Automatic driver GPS transmission requires a client integration.
- Screens need status refresh/polling; stored token lists are not live estimate feeds.
- Rate limits are in memory; multi-instance hosting needs a shared store and reviewed
  proxy configuration.

## Contributing

Work in the appropriate component branch. Coordinate API response changes with client
developers and deployment. Commit only intended files. Keep `.env`, API keys,
database credentials, signing material, passwords, OTPs and access tokens out of Git.
