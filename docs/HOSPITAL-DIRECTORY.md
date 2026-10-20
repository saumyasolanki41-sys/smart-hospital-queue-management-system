# Hospital directory

The dataset covers 24 common clinical departments with two sample doctor
profiles each. These are fictional project profiles, not a list of every specialty or
real hospital employees. Doctor names start with `Dr`. Experience, fees in
INR, consultation duration and availability are illustrative values.

From the project root, run:

```powershell
npm.cmd --prefix backend run seed:hospital
```

The command uses the MongoDB database configured in `backend/.env`, with the same
`hospital_queue` database name as the server. It requires Atlas or a replica set.
It preserves existing records, reuses department names without case sensitivity,
and skips an existing doctor with the same name and department. It does not
reset edited fees, availability, login links, tokens or ambulance data. Run one
seed process at a time. All directory inserts share a transaction.

Data lives in `backend/data/hospital.json`; the loader is `backend/seed-hospital.js`.
Doctor directory profiles do not create login credentials. To use a doctor
dashboard, provision a separate verified doctor-role account and link its user ID
using the existing admin doctor profile update endpoint.

The first ten department names match the currently supported ML specialties.
Other departments remain bookable and use the existing waiting-time fallback
where the ML specialty is unsupported. Do not label every estimate as ML.

Directory APIs paginate results. To see this full catalogue, use:

```text
GET /api/departments?limit=50
GET /api/doctors?limit=50&page=1
GET /api/doctors?limit=50&page=2
GET /api/doctors?departmentId=ACTUAL_DEPARTMENT_ID&limit=50
```

The API defaults to 20 items and allows at most 50 per page. Existing doctors may
increase the total beyond 50, so the frontend must continue fetching pages as
needed. The shared hosted API shows these records when it uses the same database;
seeding does not itself deploy backend code.
