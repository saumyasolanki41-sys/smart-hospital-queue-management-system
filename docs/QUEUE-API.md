# Patient queue tokens

This step implements same-day OPD queue tokens, not appointment time slots.
Local base URL: `http://localhost:8080`. The new routes are available on the shared
HTTPS URL only after this revision is pushed and deployed.

All routes require a verified patient's application access token:

```text
Authorization: Bearer PATIENT_ACCESS_TOKEN
```

Admin, doctor and receptionist accounts receive 403. Keep your administrator
account for directory management and use a separate registered patient account
to test booking. Do not change the administrator account back and forth for testing.

| Method | Path | Purpose | Success |
| --- | --- | --- | --- |
| POST | `/api/queue/tokens` | Join today's queue | 201 |
| GET | `/api/queue/tokens/mine` | List own tokens | 200 |
| GET | `/api/queue/tokens/:id` | Read own token and waiting count ahead | 200 |
| PATCH | `/api/queue/tokens/:id/cancel` | Cancel own waiting token | 200 |

## Join today's queue

Get an available doctor's `_id` from GET `/api/doctors?isAvailable=true`.
POST `/api/queue/tokens` with JSON:

```json
{ "doctorId": "507f1f77bcf86cd799439012" }
```

Replace the example ID with the actual doctor's ID. No other body fields are
accepted. Patient ID, date, number and initial status are assigned by the server.

201 response:

```json
{
  "success": true,
  "data": {
    "token": {
      "_id": "507f1f77bcf86cd799439013",
      "doctor": "507f1f77bcf86cd799439012",
      "queueDate": "2026-10-18",
      "tokenNumber": 1,
      "status": "waiting",
      "createdAt": "2026-10-18T06:00:00.000Z"
    }
  }
}
```

Queue day uses India time (UTC+05:30). Numbering starts at 1 separately for each
doctor and date. Each patient can have one active token per doctor per day.
Booking with different doctors is allowed. A cancelled token can be followed by
a new booking, which gets a new number; old numbers are never reused.

Doctor availability is checked again inside the booking transaction. Turning a
doctor unavailable prevents new bookings; it does not cancel existing tokens.
Counter increment and token creation share one transaction. Unique indexes protect
daily token numbers and active patient bookings. QueueDay keeps a counter per
doctor/date; QueueToken stores the actual booking. Neither is deleted overnight.
There is no queue capacity, future-day booking, schedule or payment in this step.

If a booking request loses its response, check `/tokens/mine` before retrying.
Do not display a second successful booking when receiving a duplicate/conflict error.

## My tokens

```text
GET /api/queue/tokens/mine
GET /api/queue/tokens/mine?date=2026-10-18&page=1&limit=20
```

Date defaults to today's India date. It must be a real YYYY-MM-DD date. Page
defaults to 1 (maximum 100000); limit defaults to 20 (maximum 50). Other query
fields are rejected. Responses contain `data.tokens`, `data.date`, `data.page`
and `data.limit`. Only the signed-in patient's tokens are selected, including
cancelled/history records. Empty lists return 200. Tokens sort newest first.

For this list, `doctor` is populated as `{ _id, name, specialization }` rather
than the plain ID returned by booking/detail/cancellation. No patient information
is exposed. A profile removed through direct database administration may populate
as null. There is no public list of patients in the queue.

## Token status

```text
GET /api/queue/tokens/507f1f77bcf86cd799439013
```

Returns `data.token` and `data.peopleAhead`. For a waiting token dated today,
peopleAhead counts lower-numbered tokens still waiting for the same doctor/date.
Cancelled, completed and called tokens are excluded from the count. This is a
live count, not a guaranteed appointment position or estimated waiting time.
It can change while requests are in flight. For historical or non-waiting tokens,
peopleAhead is null. Other patients' tokens return the same 404 as missing tokens.

### Estimated waiting time

For today's waiting token, the status response also contains:

```json
{
  "peopleAhead": 3,
  "estimatedWaitMinutes": 43,
  "averageConsultationMinutes": 12,
  "consultationOverdue": false
}
```

These fields are inside `data` alongside `token`. The estimate is the number of
lower-numbered waiting patients multiplied by the doctor's configured average
consultation duration, plus the estimated remaining time for the currently called
consultation. Example: 3 waiting patients × 12 minutes + 7 minutes remaining = 43.
Elapsed time since calledAt is subtracted from the current consultation's average.
Results round the remaining time up to whole minutes. When a called consultation
has reached/exceeded its average, consultationOverdue is true and its remaining
contribution stays at a minimum of one minute until staff complete it. Missing or
invalid calledAt uses a full average duration; a future calledAt is treated as
zero elapsed time. A called token carried over from an earlier date also counts.

No waiting patients ahead and no currently called consultation gives an estimate
of zero. This means no estimated queue delay, not that a staff member is ready.
Historical/non-waiting tokens have null values for estimatedWaitMinutes,
averageConsultationMinutes and consultationOverdue. If the doctor profile has
been removed, the waiting count remains available but all estimate fields are null.

The doctor's average defaults to 10 minutes and is configurable by admin through
POST/PATCH `/api/doctors`. Existing records with no valid configured duration use
10 minutes for the estimate without a database backfill. The calculation is a
configured-average estimate, not a model trained on completed consultations.
It assumes consultations continue without staff breaks or emergencies. isAvailable
only pauses new bookings and does not indicate whether staff are currently working.
Counts and current consultation are read separately and may change concurrently.
Frontend should label this as an estimated wait and refresh status as needed; do
not display it as an exact appointment time or guarantee service within that time.

## Cancel a token

```text
PATCH /api/queue/tokens/507f1f77bcf86cd799439013/cancel
```

No request body, or an empty JSON object `{}`. Requires the token's owner and
waiting status. Success returns `data.token` with status cancelled and releases
the active booking constraint. Repeated cancellation returns 409. Missing or
other patients' tokens return 404. Called/completed tokens cannot be cancelled.
Historical tokens still marked waiting can be cancelled by their owners too.

## Errors and limits

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Invalid body, ID, date, query or pagination |
| 401 | UNAUTHORIZED | Missing, expired or invalid access token |
| 403 | FORBIDDEN | Account does not have patient role |
| 404 | DOCTOR_NOT_FOUND | Doctor profile does not exist |
| 404 | TOKEN_NOT_FOUND | Token absent or not owned by caller |
| 409 | DOCTOR_UNAVAILABLE | Doctor not accepting bookings |
| 409 | ALREADY_IN_QUEUE | Existing active booking for this doctor today |
| 409 | QUEUE_CONFLICT | Concurrent booking conflict; check own tokens before retry |
| 409 | QUEUE_DAY_CHANGED | Midnight rollover during booking; retry for the new day |
| 409 | TOKEN_NOT_CANCELLABLE | Token is no longer waiting |
| 429 | RATE_LIMITED | Too many booking/cancellation attempts |
| 500 | INTERNAL_ERROR | Unexpected backend/database problem |

Booking and cancellation share 20 requests per patient per 15 minutes. Counters
are process-local. Read routes are not covered by this write limiter. Queue
responses use Cache-Control no-store through the authentication middleware.

Atlas or another replica set is required for transactions. Automated tests mock
database transactions and check query filters, schema indexes and failure paths;
they do not prove live concurrent allocation/rollback behavior. Live booking,
duplicate booking, ownership and cancellation checks are still needed.

Staff call-next/complete endpoints are documented in [STAFF-QUEUE-API.md](STAFF-QUEUE-API.md).
There is no automatic overnight status change. Old waiting tokens stay in history
and have no live peopleAhead value. Patients cannot cancel a called token.
