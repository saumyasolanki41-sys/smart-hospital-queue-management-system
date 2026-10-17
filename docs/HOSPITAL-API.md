# Departments and doctors

Local base URL: `http://localhost:8080` when local PORT is 8080.
These new endpoints are not hosted until this revision is pushed and deployed.
Use the existing shared HTTPS base URL after deployment.

GET routes are public. POST/PATCH routes require an admin account's application
access token in `Authorization: Bearer TOKEN`. Send POST/PATCH bodies as JSON.
All responses retain the existing `success`, `data` or `error` envelope.

| Method | Path | Access | Success |
| --- | --- | --- | --- |
| GET | `/api/departments` | Public | 200 |
| POST | `/api/departments` | Admin | 201 |
| GET | `/api/doctors` | Public | 200 |
| GET | `/api/doctors/:id` | Public | 200 |
| POST | `/api/doctors` | Admin | 201 |
| PATCH | `/api/doctors/:id` | Admin | 200 |

## Create a department

`POST /api/departments`

```json
{
  "name": "Cardiology",
  "description": "Heart care"
}
```

`name` is required (2–100 characters); `description` is optional (up to 500).
Names are trimmed and unique without regard to case. Duplicate names return 409
`DEPARTMENT_EXISTS`. Success returns `data.department` with `_id`, `name` and
`description`. Copy its `_id` into the doctor's `departmentId` field.

## Create a doctor profile

`POST /api/doctors`

```json
{
  "name": "Dr Test Patient",
  "departmentId": "507f1f77bcf86cd799439011",
  "specialization": "Cardiologist",
  "experienceYears": 5,
  "consultationFee": 500,
  "isAvailable": true
}
```

Replace departmentId with an existing department's real `_id`. Required fields:
name, departmentId and specialization. Name and specialization contain 2–100
characters. Experience is an integer 0–80, default 0. Consultation fee is a number
0–100000 in INR, default 0. isAvailable is a boolean, default true.

Success returns:

```json
{
  "success": true,
  "data": {
    "doctor": {
      "_id": "507f1f77bcf86cd799439012",
      "name": "Dr Test Patient",
      "department": { "_id": "507f1f77bcf86cd799439011", "name": "Cardiology" },
      "specialization": "Cardiologist",
      "experienceYears": 5,
      "consultationFee": 500,
      "isAvailable": true
    }
  }
}
```

These are public directory profiles, separate from User authentication accounts.
Creating a profile does not create login credentials, assign a doctor role or link
an existing user. Linking profiles to staff accounts will be a separate feature.
Availability is an admin-managed display flag; schedules, slots and appointment
booking are not implemented in this step. Fees are informational; no payment is made.

## List and filter

```text
GET /api/departments?page=1&limit=20
GET /api/doctors?page=1&limit=20
GET /api/doctors?departmentId=507f1f77bcf86cd799439011&isAvailable=true
```

Both lists support page (default 1, maximum 100000) and limit (default 20,
maximum 50). Departments return `data.departments`; doctors return `data.doctors`.
Both return `data.page` and `data.limit`. Results sort by name, then ID; empty
results return an empty array with 200. No total count is returned. Continue to
the next page until fewer than limit results are returned.

Doctor filters: optional departmentId and isAvailable (`true` or `false` strings
in the URL). Without isAvailable, both available and unavailable profiles appear.
An unused but valid department ID returns an empty list. Other query fields,
malformed IDs, repeated values and invalid page/limit values return 400.

## Detail and update

```text
GET /api/doctors/507f1f77bcf86cd799439012
PATCH /api/doctors/507f1f77bcf86cd799439012
```

Example PATCH body:

```json
{ "isAvailable": false, "consultationFee": 600 }
```

Send at least one supported doctor field. You may change departmentId to another
existing department. Updates return the same `data.doctor` shape as creation.
Extra fields, including role, userId and MongoDB update operators, are rejected.
There are no delete routes; temporarily hide availability using isAvailable.

## Errors and setup

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Invalid body, query, ID, type or range |
| 401 | UNAUTHORIZED | Missing, expired or invalid application token |
| 403 | FORBIDDEN | Authenticated account is not admin |
| 404 | DEPARTMENT_NOT_FOUND | Referenced department does not exist on a write |
| 404 | DOCTOR_NOT_FOUND | Doctor detail/update target does not exist |
| 409 | DEPARTMENT_EXISTS | Duplicate department name |
| 500 | INTERNAL_ERROR | Unexpected backend/database failure |

Existing public registration creates patients only. For the initial administrator,
the project owner must provision the admin role for their own verified account
through trusted database administration. Never add public role selection to sign-up.
After trusted provisioning, log in normally and use the resulting application token.
No accounts or roles were changed by implementing this feature.

Tests cover HTTP routing, role checks, validation, pagination, filters and error
handling with mocked database calls, plus actual Mongoose schema validation. Live
database creation and concurrent duplicate-name writes have not been exercised.
Department uniqueness is enforced by its MongoDB unique collation index, initialized
before department creation. Existing authentication data is unchanged.
