# Ambulance records and location

Local base URL: `http://localhost:8080`. Restart the backend after code changes.
New endpoints are available on the shared HTTPS URL only after deployment.
This step stores staff-managed vehicle records; no external GPS or ML integration
is included. No real ambulance is contacted or dispatched by these endpoints.

Every route requires an application Bearer token. Admins can create, list, view
and update. Receptionists can list, view and update. Patient/doctor roles receive
403. Driver contact and vehicle location are not public.

| Method | Path | Success | Purpose |
| --- | --- | --- | --- |
| POST | `/api/ambulances` | 201 | Admin creates a vehicle record |
| GET | `/api/ambulances` | 200 | Staff lists vehicles |
| GET | `/api/ambulances/:id` | 200 | Staff reads one vehicle |
| PATCH | `/api/ambulances/:id` | 200 | Staff changes record, status or location |

POST/PATCH use Content-Type application/json. Authentication:

```text
Authorization: Bearer STAFF_ACCESS_TOKEN
```

## Create a vehicle

```json
{
  "vehicleNumber": "UP14AB1234",
  "driverName": "Test Driver",
  "driverPhone": "+919876543210"
}
```

These are examples; use your own test values. All three fields are required.
Vehicle numbers are normalized to uppercase with spaces/hyphens removed, then
must contain 4–20 letters/digits. Formatting variants identify the same vehicle.
This validates a storage identifier, not an official registration database.
Driver names contain 2–100 characters; phone numbers are strings of 10–15 digits,
not starting with zero, optionally prefixed with +. Phone ownership is not verified.

Status defaults to available. Allowed statuses: available, busy, maintenance.
An optional location object may be supplied. Example 201 response:

```json
{
  "success": true,
  "data": {
    "ambulance": {
      "_id": "507f1f77bcf86cd799439012",
      "vehicleNumber": "UP14AB1234",
      "driverName": "Test Driver",
      "driverPhone": "+919876543210",
      "status": "available",
      "createdAt": "2026-10-18T06:00:00.000Z",
      "updatedAt": "2026-10-18T06:00:00.000Z"
    }
  }
}
```

An ambulance created without location has no location field until staff supply it.
available is a manually managed inventory status, not a guarantee of staffed
emergency service, fresh GPS or a completed dispatch reservation.

## Lists and details

```text
GET /api/ambulances?status=available&page=1&limit=20
GET /api/ambulances/ACTUAL_AMBULANCE_ID
```

status is optional. Page defaults to 1 (maximum 100000), limit to 20 (maximum 50).
Unsupported/repeated query fields and invalid status values return 400. Lists
sort by normalized vehicleNumber, then ID, and return `data.ambulances`, `page`
and `limit`. Empty lists return 200. Detail returns `data.ambulance`.

## Update status/location

PATCH `/api/ambulances/ACTUAL_AMBULANCE_ID`:

```json
{
  "status": "busy",
  "location": { "latitude": 28.6692, "longitude": 77.4538 }
}
```

Send at least one supported field: vehicleNumber, driverName, driverPhone, status,
location. Fields not supplied are preserved. Status-only updates preserve the
last location and its timestamp. Updating driver details does not create a login
account or driver role.

Both coordinates must be finite JSON numbers. Latitude is -90 to 90 and longitude
is -180 to 180; zero is valid. The server adds `location.updatedAt`, the time the
update was accepted. Callers cannot supply that timestamp, other location fields
or partial coordinates. This timestamp is not the GPS device's measurement time.
Location is supplied by authorized staff here; no automatic location tracker is
running. Review the timestamp before relying on a location. Concurrent edits use
last accepted write for the supplied fields; there is no event history or version check.

Success returns the updated `data.ambulance`. Vehicle number conflicts return
409 on create or update. There is no delete endpoint; maintenance can mark a
vehicle unavailable for operational use. An assigned vehicle rejects status changes
with 409 AMBULANCE_ASSIGNED; finish or cancel its active request first. Location
and driver detail updates remain allowed. Patient transport requests and staff
reservations are documented in [Ambulance requests](AMBULANCE-REQUEST-API.md).
Driver login, routing, maps and ETA predictions remain separate work.
ML integration will be added after its input/output contract is agreed.

## Errors and verification

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Invalid fields, ranges, types, ID or pagination |
| 401 | UNAUTHORIZED | Missing/invalid/expired application token |
| 403 | FORBIDDEN | Account lacks access; receptionist cannot create |
| 404 | AMBULANCE_NOT_FOUND | Vehicle record does not exist |
| 409 | VEHICLE_EXISTS | Normalized vehicle number is already registered |
| 429 | RATE_LIMITED | More than 120 combined create/update requests per staff user per 15 minutes |
| 500 | INTERNAL_ERROR | Unexpected backend/database failure |

Responses use Cache-Control no-store. Write limits use an in-memory per-user store.
MongoDB's unique vehicleNumber index is initialized before writes. Automated tests
cover validation, staff permissions, query filters, timestamps, duplicate errors
and actual schema validation with mocked database operations. Live create/update
and concurrent unique-index enforcement still need an integration check.

Postman: Ambulance records folder. Set staffAccessToken to an admin login token.
Create saves ambulanceId automatically. Test list/detail, then update status and
location using the saved ID. These requests call your backend only; no frontend,
map provider or ML service needs to be connected.
