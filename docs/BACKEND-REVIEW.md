# Backend review - 2026-10-19

Scope: current backend source, tests, API guides and Postman collection. The
repository has a short README rather than a complete acceptance specification;
this review checks the implemented scope and previously discussed workflows.
It does not certify that every possible hospital requirement is covered.

## Implemented scope

| Area | Current behavior |
| --- | --- |
| Authentication | Registration OTP, password plus login OTP, Google ID-token exchange, profile, password reset |
| Access control | Patient, doctor, receptionist and admin role checks; current database role and token version checked |
| Hospital directory | Department creation/listing; doctor creation, listing, detail and update; admin links doctor login |
| Patient queue | Daily India-date token allocation, duplicate active booking protection, own list/status/cancel |
| Staff queue | Doctor ownership checks, call next, complete and skip; one called token per doctor |
| Waiting estimate | Configured average consultation duration and remaining current consultation time; not ML |
| Staff dashboard | Hospital directory totals and selected-day token status counts |
| Doctor dashboard | Linked profile, its selected-day token counts and current called patient |
| Ambulance inventory | Staff-only records, driver contact, manual status/location; active assignment protects status |
| Transport requests | Patient ownership, one active request, staff assignment, complete/cancel and vehicle release |
| API delivery | Health endpoint, bounded JSON bodies, generic errors, pagination, rate limits and API/Postman guides |

Public registration creates patient accounts only. Creating staff roles is a
trusted database administration step, not a public API. Admin doctor-profile
linking does not create a login or change a user's role. No refresh-token or
server logout endpoint is implemented; access tokens expire after 15 minutes.

## Fixes made in this review

- Password reset now rejects passwords consisting entirely of whitespace,
  consistent with registration. Meaningful leading/trailing spaces are preserved.
- Registration/login challenge updates use returnDocument after instead of the
  deprecated new option that was producing Mongoose warnings.
- Local authentication examples now use the project's current 8080 setup and
  explain that the source/.env.example default remains 5000.

## Verification and limits

The npm dependency audit reported zero known production dependency vulnerabilities
at review time. All 71 JavaScript files in src/tests/scripts passed node --check.
All 41 Postman requests parsed, including raw JSON bodies and capture scripts.
The automated suite passed 180 tests with zero failures after the fixes. It runs
real local HTTP and JWT/schema checks with mocked database/provider operations.

User-reported manual local checks cover department/doctor creation, queue flows,
ambulance inventory and transport request/assignment/completion/cancellation, and
the doctor dashboard. These reports are distinct from independent automated checks.
The review did not mutate Atlas records, send email, deploy or change credentials.

## Remaining before a complete deployed demonstration

1. Deploy the latest committed backend and verify the hosted health endpoint,
   login/OTP and role-specific workflows on that exact revision.
2. Verify transaction/index behavior with simultaneous requests against an isolated
   test replica set: competing queue bookings, assignments and completion/cancel.
   Mocked rollback tests do not prove live MongoDB concurrency behavior.
3. Check reverse-proxy rate limiting on the chosen host. The app has no explicit
   trust proxy configuration; IP limits can group clients behind a proxy. Do not
   blindly trust caller-supplied forwarding headers. Limits are currently per
   process and reset on restart; multiple instances need a shared store.
4. Revoke/replace any secrets exposed in screenshots before a shared deployment.
   Earlier screenshots showed a real environment file. Keep .env out of Git and
   future screenshots. No secret values are copied into this review.
5. Finish the final project README/setup handoff after the agreed scope is settled.

## Explicitly deferred

Frontend/mobile integration and ML integration remain last, as requested. The ML
teammate owns waiting-time prediction and ambulance ETA models; model contracts
and backend connections are not implemented. Browser origin configuration must
be confirmed when integration starts. Driver login, automatic GPS, map routing,
notifications and reassignment are not part of the current transport workflow;
add them only if required by the project specification.

Current result: the discussed core backend features are implemented. Production
verification, final handoff and deferred integrations remain; a percentage or
claim of complete production readiness would not be supported by these checks.
