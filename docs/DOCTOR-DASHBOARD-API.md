# Doctor dashboard

GET `http://localhost:8080/api/doctor/dashboard`

Use the logged-in doctor's application Bearer token. Body: none. Only the doctor
role is allowed. Admin/receptionist accounts use `/api/staff/dashboard` instead.
Restart the local server after code changes; hosted use requires deployment.

An admin must first link the verified doctor-role login to a doctor profile through
the existing doctor POST/PATCH `userId` field. A role alone is insufficient: an
unlinked account receives 404 DOCTOR_NOT_FOUND. No role or profile is created here.

The server resolves the profile using the authenticated user ID. Callers cannot
override doctorId, userId or role. The returned doctor `_id` is the profile ID used
by existing staff queue endpoints, not the login account ID.

Optional query: `?date=2026-10-19`. Date must be a real YYYY-MM-DD date; default is
today in Asia/Kolkata. Extra or repeated query fields return 400.

Example response, with no called patient:

```json
{
  "success": true,
  "data": {
    "date": "2026-10-19",
    "doctor": {
      "_id": "507f1f77bcf86cd799439012",
      "name": "Dr Test",
      "department": { "_id": "507f1f77bcf86cd799439014", "name": "Cardiology" },
      "specialization": "Cardiologist",
      "isAvailable": true,
      "averageConsultationMinutes": 10
    },
    "tokens": {
      "total": 6,
      "waiting": 3,
      "called": 0,
      "completed": 2,
      "cancelled": 0,
      "skipped": 1
    },
    "currentToken": null
  }
}
```

Counts include only this doctor's tokens with the selected queueDate. Each token
is counted by its current status; historical queries are not end-of-day snapshots.
Repeated bookings count as separate tokens, not unique patients. Missing statuses
return zero. Legacy profiles may lack averageConsultationMinutes.

`currentToken` is the live called token across all dates, even for historical
queries. This keeps unfinished previous-day consultations visible. It includes
token `_id`, doctor ID, queueDate, tokenNumber, status, calledAt, createdAt and
patient `{_id, name}` (or null if that account was removed). No email, password,
phone or another doctor's patients are exposed. The day's called count can be
zero while currentToken is non-null.

Profile, counts and current token are independent reads, not an atomic snapshot.
Refresh after queue changes. Availability describes acceptance of bookings, not
an online indicator. This endpoint returns no waiting-list array. Use:

```text
GET /api/staff/queues/doctors/DOCTOR_PROFILE_ID/tokens
POST /api/staff/queues/doctors/DOCTOR_PROFILE_ID/call-next
PATCH /api/staff/queues/doctors/DOCTOR_PROFILE_ID/tokens/TOKEN_ID/complete
PATCH /api/staff/queues/doctors/DOCTOR_PROFILE_ID/tokens/TOKEN_ID/skip
```

These existing routes enforce doctor-profile ownership. See
[STAFF-QUEUE-API.md](STAFF-QUEUE-API.md). No frontend or ML integration is included.

Errors: 400 VALIDATION_ERROR, 401 UNAUTHORIZED, 403 FORBIDDEN, 404 DOCTOR_NOT_FOUND,
500 INTERNAL_ERROR. Responses use Cache-Control no-store. Database errors remain
generic. Automated tests cover real HTTP/JWT permissions, profile isolation,
ObjectId aggregation filters, dates, empty counts and previous-day consultations
with mocked database operations. Live database summary verification remains.

Postman folder: Doctor dashboard. Set doctorAccessToken from a doctor-role login
and baseUrl to `http://localhost:8080` for local work.
