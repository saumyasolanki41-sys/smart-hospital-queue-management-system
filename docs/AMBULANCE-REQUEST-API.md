# Ambulance transport requests

Local base URL: `http://localhost:8080`. Restart the server after pulling changes.
Hosted endpoints require deployment first. These APIs store requests and staff
assignments. Booking/assignment do not contact drivers or emergency services.
The separate ETA endpoint can call routing, weather and ML when configured;
see [ML-INTEGRATION.md](ML-INTEGRATION.md). Use test data for manual checks.

All endpoints require Authorization: Bearer ACCESS_TOKEN. Patient accounts create
requests and read only their own records. Admins/receptionists read all requests
and assign, complete or cancel them. Doctor accounts receive 403.

| Method | Path | Role | Success |
| --- | --- | --- | --- |
| POST | `/api/ambulance-requests` | Patient | 201 |
| GET | `/api/ambulance-requests` | Patient (own), staff (all) | 200 |
| GET | `/api/ambulance-requests/:id` | Owner or staff | 200 |
| GET | `/api/ambulance-requests/:id/eta` | Owner or staff | 200 |
| PATCH | `/api/ambulance-requests/:id/assign` | Staff | 200 |
| PATCH | `/api/ambulance-requests/:id/complete` | Staff | 200 |
| PATCH | `/api/ambulance-requests/:id/cancel` | Owner or staff | 200 |

## Create and read

POST body, raw JSON:

```json
{
  "pickupAddress": "Gate 2, Test Road, Ghaziabad",
  "latitude": 28.6692,
  "longitude": 77.4538,
  "contactPhone": "+919876543210"
}
```

All four fields are required; extra fields are rejected. Address: 5 to 300
characters without control characters. Latitude: finite number -90 to 90;
longitude: finite number -180 to 180. Phone: string of 10 to 15 digits, optional
leading +, first digit nonzero. Zero coordinates are valid. Phone ownership is
not verified. The logged-in patient is recorded by the server.

201 returns `data.request`, including `_id`, `status: pending`, pickup fields,
patient ID and timestamps. Only one active (pending or assigned) request per
patient is allowed. A terminal request permits a new booking.

GET list supports optional `status=pending|assigned|completed|cancelled`, `page`
(default 1, maximum 100000), `limit` (default 20, maximum 50). Extra/repeated
query fields return 400. Returns `data.requests`, `page`, `limit`, newest first.
Detail returns `data.request`; another patient's record returns 404. Ambulance
references include only ID and current vehicle number, or null if deleted by
database administration. Driver phone and live vehicle GPS are staff inventory
data and are not exposed in request responses. Pickup contact/location remain
visible only to the patient who requested transport and authorized staff.

## Assign and finish

PATCH `/api/ambulance-requests/REQUEST_ID/assign`, with staff token:

```json
{ "ambulanceId": "ACTUAL_AMBULANCE_ID" }
```

Only a pending request and an available, unassigned ambulance can be assigned.
Success sets request status assigned, assignedAt and ambulance reference; vehicle
becomes busy. Missing/unavailable vehicle returns 409. Missing request returns
404; nonpending request returns 409.

PATCH `/api/ambulance-requests/REQUEST_ID/complete` uses no body or `{}` and a
staff token. Only an assigned request can complete. Success marks it completed,
sets completedAt and releases the ambulance to available.

PATCH `/api/ambulance-requests/REQUEST_ID/cancel` also uses no body or `{}`.
Patients can cancel only their own pending requests. Staff can cancel pending
or assigned requests; assigned cancellation releases the vehicle. Terminal
requests cannot be cancelled/completed again. Staff must coordinate any physical
transport separately before recording a cancellation/completion.

Vehicle status cannot be changed through inventory PATCH while assigned (409
AMBULANCE_ASSIGNED). Staff can still update its location and driver details.
Returned vehicle details reflect current inventory, not an assignment snapshot.
There is no reassignment, pickup stage or driver login. Arrival estimates use
the separate ETA endpoint; unavailable estimates return null with a reason.

## Consistency and errors

Assignment and closure use MongoDB transactions (replica set/Atlas required).
The request and vehicle reservation change together or roll back together.
Conditional writes and unique indexes prevent two active requests per patient
or two assigned requests per vehicle. Vehicle reservation matching prevents a
stale completion from releasing another request's vehicle. Indexes initialize
before writes; existing duplicate data must be resolved before initialization.

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Invalid body, ID, coordinate or pagination |
| 401 | UNAUTHORIZED | Missing/expired/invalid login token |
| 403 | FORBIDDEN | Wrong account role |
| 404 | REQUEST_NOT_FOUND | Missing request or not owned by patient |
| 409 | ACTIVE_REQUEST_EXISTS | Patient already has an active request |
| 409 | AMBULANCE_UNAVAILABLE | Vehicle missing, busy, reserved or maintenance |
| 409 | REQUEST_CONFLICT | Invalid transition, stale assignment or closed request |
| 429 | RATE_LIMITED | Over 60 combined writes per user per 15 minutes |
| 500 | INTERNAL_ERROR | Unexpected database/backend error |

Responses use no-store. Rate limits are in memory per server process. Automated
tests use mocked database operations and rollback simulation plus real HTTP/JWT
and schema validation. Live Atlas transaction/concurrency checks remain separate.

## Manual test sequence

1. With staff token, make the test ambulance available using inventory PATCH
   `{"status":"available"}` if it was manually marked busy previously.
2. With patient token, create request and copy its ID.
3. With staff token, assign the available test ambulance. Expect assigned/busy.
4. With patient token, GET the request; then verify cancel returns 409 once assigned.
5. With staff token, complete it. Expect completed and vehicle available again.
6. Use a new request to test patient pending cancellation or staff assigned cancellation.

Postman folder: Ambulance transport requests. Variables: accessToken (patient),
staffAccessToken, ambulanceId and ambulanceRequestId. Create captures request ID.
