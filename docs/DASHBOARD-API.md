# Staff dashboard summary

GET `/api/staff/dashboard`

Local URL: `http://localhost:8080/api/staff/dashboard`. Restart the local server
after adding this revision. The endpoint is available on the shared HTTPS base
only after the revision is pushed and deployed.

No request body. Requires an admin or receptionist application access token:

```text
Authorization: Bearer STAFF_ACCESS_TOKEN
```

Example HTTP 200 response:

```json
{
  "success": true,
  "data": {
    "date": "2026-10-18",
    "departments": 3,
    "doctors": { "total": 5, "available": 4 },
    "tokens": {
      "total": 10,
      "waiting": 4,
      "called": 1,
      "completed": 3,
      "cancelled": 2,
      "skipped": 0
    }
  }
}
```

Actual counts depend on your database. All empty counters are zero.

- date defaults to today in India (UTC+05:30).
- departments counts current department records.
- doctors.total counts current directory profiles, not login accounts.
- doctors.available counts profiles with isAvailable true. This means accepting
  new bookings; it does not guarantee that the doctor is online or not busy.
- tokens counts records with queueDate equal to the selected date, by their
  current status. Total includes cancelled and skipped records and is not a unique
  patient count. skipped represents patients marked absent after being called;
  it is distinct from a patient cancellation or completed consultation.
- No names, patient IDs, emails, credentials or raw token records are returned.

To request another day:

```text
GET /api/staff/dashboard?date=2026-10-17
```

Only date is accepted, as a real YYYY-MM-DD calendar date. Duplicate date parameters,
objects and unsupported query fields are rejected. Future valid dates normally
return zero token counts because booking supports today only.

Date filters token records only. Department/doctor counts always describe the
current directory, including when requesting a historical date. Historical token
status counts are the records' current states, not an end-of-day snapshot. A
called token from yesterday is counted under yesterday, not in today's called
count; use the staff queue endpoint's currentToken to handle carry-over consultations.
Counts are read in separate database operations and can change during a request;
this endpoint is a live dashboard, not a transactionally consistent financial report.

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Invalid/repeated date or unsupported query fields |
| 401 | UNAUTHORIZED | Missing/invalid/expired application token |
| 403 | FORBIDDEN | Patient or doctor role; global summary requires admin/receptionist |
| 500 | INTERNAL_ERROR | Unexpected backend/database failure |

Responses use Cache-Control no-store. There is no export or write action. The
frontend can refresh this endpoint when needed; no live socket subscription is
implemented. A non-unique queueDate/status index supports the token report query.
No existing records or roles are modified by this feature.

Postman: Staff queue > Dashboard summary. Set staffAccessToken to an admin or
receptionist login token. Automated tests verify roles, safe response shape,
date validation, zero defaults and error handling with mocked database calls.
Actual database aggregation counts still require a local/live integration check.
