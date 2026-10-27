# Staff queue management

Local base URL: `http://localhost:8080`. Restart the local backend after changing
code. These endpoints are not available on the shared HTTPS URL until deployed.

All routes require an application access token for admin, receptionist or doctor.
Patients receive 403. Admins and receptionists can manage any doctor queue.
Doctors can manage only the profile linked to their verified User account.

```text
Authorization: Bearer STAFF_ACCESS_TOKEN
```

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/staff/queues/doctors/:doctorId/tokens` | View today's queue and current called token |
| POST | `/api/staff/queues/doctors/:doctorId/call-next` | Call the lowest waiting token |
| PATCH | `/api/staff/queues/doctors/:doctorId/tokens/:tokenId/complete` | Complete a called consultation |
| PATCH | `/api/staff/queues/doctors/:doctorId/tokens/:tokenId/skip` | Mark a called patient as absent |

All successful responses use HTTP 200 and `{ success: true, data: ... }`.
POST/PATCH accept no body or `{}`. The server chooses the next token; do not
send a patient, token number, status or date override.

## Link a doctor login account

This is optional for admin/receptionist testing. To enable a doctor's own login:

1. Create and verify a separate account through normal registration.
2. The project owner provisions that account's doctor role through trusted
   database administration. Public registration cannot assign staff roles.
3. Log in as that doctor and obtain the account ID from `data.user.id`.
4. Using an admin token, PATCH the existing doctor directory profile:

```text
PATCH /api/doctors/ACTUAL_DOCTOR_PROFILE_ID
```

```json
{ "userId": "ACTUAL_DOCTOR_LOGIN_USER_ID" }
```

Replace both IDs. This links an existing verified doctor account; it does not
create credentials or change any role. An account can link to at most one profile.
Admin can reassign a profile to a different eligible account using the same field.
Public doctor responses do not expose the linked login account ID. Existing
unlinked directory profiles continue to work for patient booking and admin staff
actions; doctor-role requests for an unlinked profile receive 403.

Missing/unverified/non-doctor account: 404 `DOCTOR_ACCOUNT_NOT_FOUND`.
Account already linked to another profile: 409 `DOCTOR_ACCOUNT_LINKED`.
These also apply to the optional userId field on POST `/api/doctors`.
No staff roles or profile links were changed while implementing this feature.

## View queue

```text
GET /api/staff/queues/doctors/ACTUAL_DOCTOR_ID/tokens?page=1&limit=20&status=waiting
```

Date is today's India date (UTC+05:30). Status defaults to waiting; supported
filters: waiting, called, completed, cancelled, skipped. Page defaults to 1, maximum 100000;
limit defaults to 20, maximum 50. Other/repeated query fields are rejected.
Tokens sort by tokenNumber ascending.

```json
{
  "success": true,
  "data": {
    "tokens": [],
    "currentToken": null,
    "date": "2026-10-18",
    "page": 1,
    "limit": 20
  }
}
```

Token fields: `_id`, `doctor` ID, `patient: { _id, name }`, queueDate, tokenNumber,
status, createdAt, and calledAt/completedAt/skippedAt when set. Emails, credentials and
other patient profile fields are not selected. A deleted user may populate as null.

currentToken is the currently called token for this doctor, even if carried over
from an earlier day. It must be completed or skipped before another is called.
The list and current token are read separately and can change during concurrent
requests; refresh after actions. These patient names are available only to
authorized staff and must not be placed on a public queue display.

## Call next and complete

POST `/api/staff/queues/doctors/ACTUAL_DOCTOR_ID/call-next` selects the lowest-numbered
active waiting token for today and atomically changes waiting to called, setting
calledAt. Response: `data.token`. Save its `_id` for completion.

Only one token per doctor can have called status across all dates. A partial unique
MongoDB index enforces this, including simultaneous call-next requests from separate
staff members. A second call while busy returns 409 `QUEUE_BUSY`. No waiting tokens
returns 409 `QUEUE_EMPTY`. Cancelled/completed/skipped tokens are ignored automatically.
Doctor isAvailable controls new bookings; staff may still serve an existing queue
when that flag is false.

PATCH `/api/staff/queues/doctors/ACTUAL_DOCTOR_ID/tokens/ACTUAL_QUEUE_TOKEN_ID/complete`
atomically changes a matching called token to completed, sets completedAt and clears
its active booking flag. Response: `data.token`. The next patient can then be called.
An old-day called token can also be completed. Completion cannot skip the waiting
stage, revive a cancelled token or complete a token for a different doctor.

### Skip an absent patient

PATCH `/api/staff/queues/doctors/ACTUAL_DOCTOR_ID/tokens/ACTUAL_QUEUE_TOKEN_ID/skip`
with no body or `{}`. Use the currently called token ID, not the patient or doctor ID.
Success is 200 with `data.token.status` equal to skipped and skippedAt set. The
active booking flag is cleared, so the next patient can be called. This works for
a called token carried over from an earlier day too. Waiting, cancelled, completed
or already skipped tokens return 409 TOKEN_NOT_CALLED. Other/missing doctor tokens
return 404. Permissions and doctor ownership are the same as completion.

Completion and skipping both conditionally update called status; competing requests
cannot both change the same token. There is no automatic timeout or recall endpoint.
A skipped patient can join again through POST `/api/queue/tokens` if the doctor is
available, receiving a new number at the end. The old number is never restored.
This is a new active booking, not a second concurrent token.

Patient read endpoints report called/completed/skipped status after refresh.
calledAt, completedAt and skippedAt are included when set. Once called or skipped,
the patient cannot cancel the token. Skipped records do not count toward waiting
estimates. The dashboard includes a separate tokens.skipped count. Frontend/mobile
status handling should accept the new skipped enum value.
No real-time socket notifications are included. Configured-average waiting-time
estimates are documented in QUEUE-API.md.

## Errors and limits

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Invalid ID, body, status filter or pagination |
| 401 | UNAUTHORIZED | Missing/expired/invalid application access token |
| 403 | FORBIDDEN | Non-staff account or doctor accessing another/unlinked queue |
| 404 | DOCTOR_NOT_FOUND | Doctor directory profile does not exist |
| 404 | TOKEN_NOT_FOUND | Token absent or belongs to a different doctor |
| 409 | QUEUE_BUSY | A consultation is already called; refresh before retrying |
| 409 | QUEUE_EMPTY | No waiting tokens for this doctor today |
| 409 | TOKEN_NOT_CALLED | Waiting, cancelled, skipped or already completed token |
| 429 | RATE_LIMITED | More than 100 combined call/complete/skip requests per staff user per 15 minutes |
| 500 | INTERNAL_ERROR | Unexpected database/backend failure |

Write rate limits are process-local. Responses use Cache-Control no-store through
authentication. A lost action response should be followed by a queue refresh before
retrying: call-next is an action, not an idempotent lookup.

## Database and verification

Additive schema fields: Doctor.user, QueueToken.calledAt, QueueToken.completedAt,
QueueToken.skippedAt. QueueToken.status also accepts skipped; existing records need
no backfill. Schema/index changes are not live until the new revision is deployed.
Indexes: unique sparse Doctor.user and one called token per doctor. The existing
patient/doctor/day active-booking index is unchanged. call-next waits for QueueToken
indexes to initialize; profile writes wait for Doctor indexes to initialize.
If existing data was manually assigned multiple called tokens for one doctor or
the same account to multiple doctor profiles, resolve it before creating these
indexes. This change does not delete data or automatically rewrite conflicting rows.

Automated tests exercise HTTP roles, doctor ownership, FIFO query selection,
conditional state changes, unique-index conflict handling, data selection and safe
errors with mocked database calls. Live simultaneous call-next behavior is still
an integration check; the mocked tests do not independently verify MongoDB races.

Manual flow: book a token with a patient login, switch to an admin login, view the
queue, call next, confirm another call receives QUEUE_BUSY, complete the returned
token, and check the patient's status. Keep patient and staff tokens separate.

The Postman collection's Staff queue folder uses `staffAccessToken`; set it from a
staff login response. `accessToken` remains the patient token for Patient queue
requests. Set doctorId to a real profile. call-next saves calledTokenId for Complete.
