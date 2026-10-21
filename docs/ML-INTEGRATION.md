# ML predictions setup and API behavior

Backend integration for the team's FastAPI service is implemented. No Axios/Zod
dependencies were added: the backend uses native fetch, checked database inputs
and validated numeric responses. Models are project estimates, not clinical triage
or a guarantee of ambulance arrival. The frontend calls this backend, not ML directly.

## Setup

Add these variables privately in backend/.env and Railway Variables:

```text
ML_SERVICE_URL=https://smart-hospital-queue-management-system-1-1ahd.onrender.com
OPENROUTESERVICE_API_KEY=YOUR_PRIVATE_ROUTING_KEY
```

Do not paste the key in chat, commit it or put it in frontend variables. Create
an OpenRouteService account/key through its dashboard. Check current plan quotas:
https://openrouteservice.org/dev/ and https://openrouteservice.org/restrictions/.
Restart the backend after local changes; apply/redeploy hosting variables there.
This change does not edit your real .env or deploy automatically.

Weather uses Open-Meteo's non-commercial endpoint, without an API key. Follow its
usage terms and attribution requirements: https://open-meteo.com/en/docs.
Road routing uses OpenRouteService/OpenStreetMap through
`https://api.heigit.org/openrouteservice/v2/directions/driving-car` following the
[provider's host migration](https://ask.openrouteservice.org/t/deprecating-api-openrouteservice-org-in-favour-of-api-heigit-org/7912).
It is a normal driving route, not emergency routing or a live traffic feed. Check provider requirements before
commercial use. Provider keys and URLs are server configuration, never request fields.

## Patient queue

The existing owner-only endpoint stays:

```text
GET /api/queue/tokens/TOKEN_ID
Authorization: Bearer PATIENT_ACCESS_TOKEN
```

Today's waiting tokens get estimatedWaitMinutes and a new prediction object:

```json
{
  "estimatedWaitMinutes": 23.4,
  "prediction": {
    "source": "ml",
    "reason": null,
    "assumptions": [
      "standard_complexity",
      "follow_up_visit",
      "no_urgency_data",
      "configured_consultation_average"
    ]
  }
}
```

This is a partial response, not an exact prediction. Inputs use only lower-number
waiting tokens ahead for the same doctor/day, current called consultation across
dates, elapsed minutes, configured averageConsultationMinutes, total completed
token count and department name. India time is used; weekday Monday=0.
Department names must match the ML specialty enums exactly (see doctor dashboard/
hospital guides). Unsupported departments use the existing baseline.

Complexity, visit type and urgency are not collected in current bookings, so all
waiting/current issues are assumed Standard, visits Follow-up and urgency absent.
These assumptions do not classify a real patient's complaint or change queue
priority. No diagnosis/name/email/ID is sent to ML. The doctor's configured average
is not a computed recent-history average. Completed-token count is real, although
it may be outside the model's original training range. Specialty median lookup
uses the values in the ML teammate's original guide.

An empty queue with no current patient returns 0 directly with source baseline.
Missing ML config, unsupported specialty, rejected input, malformed response,
timeout or outage keeps the existing queue estimate, including remaining current
consultation time and the minimum one minute for an ongoing overdue consultation.
Fallback reasons distinguish these cases. Historical/nonwaiting tokens retain
null estimates and prediction. The endpoint allows 60 checks/minute per patient.

## Ambulance arrival ETA

```text
GET /api/ambulance-requests/REQUEST_ID/eta
Authorization: Bearer PATIENT_OR_STAFF_ACCESS_TOKEN
```

Body none, no query parameters. Patient ownership, staff access and doctor-role
denial match transport request routes. Request must be assigned. Vehicle must
still be reserved for that exact request, busy and have valid coordinates updated
within 10 minutes (at most one minute in the future). This is manually supplied
location, not automatic GPS. Update it through the existing staff inventory PATCH.

The backend sends ambulance/pickup coordinate pairs to routing and pickup
coordinates to weather. Names, phone numbers, addresses and account IDs are not
sent to either provider. ML gets derived travel features, not coordinates.

Routing returns road km and ordinary driving duration. For 1-50 km trips with
current supported weather and ML configured, ML predicts arrival minutes:

```json
{
  "etaMinutes": 28.5,
  "source": "ml",
  "reason": null,
  "distanceKm": 12.2,
  "calculatedAt": "2026-10-19T10:00:00.000Z",
  "ambulanceLocationUpdatedAt": "2026-10-19T09:59:00.000Z",
  "weatherCode": 63,
  "weatherTime": "2026-10-19T10:00:00.000Z",
  "attribution": "openrouteservice / OpenStreetMap contributors; weather by Open-Meteo",
  "assumptions": [
    "moderate_traffic", "speed_40_kmh", "urban_local_road",
    "default_emergency_level", "weather_impact_equals_severity"
  ]
}
```

Values are illustrative. Show source/assumptions and provider attribution in the
frontend. Traffic_Level=2 is an assumption, not live traffic. Speed=40, Urban,
Local Road and Minor emergency are model defaults, not verified route/medical
facts. Weather code maps 0/1/2/3 to severity 0; drizzle/rain/showers 51/53/55,
61/63/65,80/81/82 to 1; thunderstorm 95/96/99 to 2. Impact equals severity as a
documented project heuristic, not a measured road-impact value. Fog, freezing
rain/snow and unknown codes use the routing fallback. Weather older than one hour
is rejected. Pickup weather does not cover every segment of the route.

Outside original 1-50 km training range, weather missing/unsupported, or ML failure:
etaMinutes uses route duration, source routing and an explicit reason. It is not
labelled ML. Missing key/route, stale coordinates, or an unassigned/closed request
returns 200 with etaMinutes null, source unavailable and a reason. No road distance
is invented from a straight-line calculation. Wrong owner/missing request is 404;
invalid ID/query 400; auth 401/403; ETA limit is 30 checks/minute per user (429).

## Availability and tests

ML has a 4-second timeout and at most one retry for network/5xx failures. No retry
for 4xx or invalid numbers. Routing and weather each have a 5-second timeout.
Successful ML responses are cached 10 seconds, routes 60 seconds and weather 5
minutes in bounded per-process caches. Provider requests are sequential for ETA;
worst-case failure latency can approach 18 seconds. Cold Render startup may use
fallback; retry later. ML health is separate from this backend's database health.

Automated tests mock providers for units, timestamps, privacy/ownership, source
labels, invalid responses, retries, fallback and routing coordinate order. Live
OpenRouteService routing, Open-Meteo weather and the ML ambulance prediction were
also verified together using synthetic coordinates and the privately configured
key. That smoke test returned a 16.3543 km road route and a 35.99 minute ML estimate;
these are test values, not a real booking. End-to-end assigned-request ETA still
requires a fresh vehicle location and an owner/staff token. No runtime dependencies changed.

## Next steps for the team

Replacement service verified on 2026-10-20: `/health` returned HTTP 200 with both
models loaded. The existing backend ML adapter successfully called queue and
ambulance prediction endpoints with synthetic inputs, returning `source: ml` and
`reason: null`. Test estimates were 47.75 queue minutes and 25.08 arrival minutes;
these are integration checks, not model accuracy measurements. Update Railway's
`ML_SERVICE_URL` to the new URL above and redeploy; local configuration alone does
not update the hosted backend. These checks do not revalidate an entire hosted
patient booking or assigned-ambulance request on the replacement service.

Hosted verification on 2026-10-19 used temporary test patients, an isolated test
doctor, queue tokens and an ambulance request. The real hosted queue flow passed:
one consultation was called, a different patient booked a waiting token, and its
status returned source ml with a 10.34 minute estimate. Another patient's access
to that token returned 404 as expected. Temporary records were deleted afterward
and zero remaining fixture records were confirmed.

The initial hosted ambulance check hit routing-provider HTTP 403. After the
correct active key was saved, the direct local routing check and the hosted
assigned-request ETA both passed. Hosted ETA returned source ml, reason null,
36.88 minutes and a 16.354 km road distance for synthetic test coordinates.
Completing the test request released the vehicle to available. All temporary
accounts, vehicle and request records were deleted and zero remaining fixture
records were confirmed. These smoke tests verify integration, not model accuracy.

1. Add ML_SERVICE_URL locally and in Railway; restart/redeploy. Test an owned
   waiting token's status and inspect prediction.source/reason.
2. Generate routing key, add it privately to both environments.
3. Staff: assign a test ambulance and update its location with current test
   coordinates. Patient/staff: GET its request ETA. Check source and attribution.
4. Frontend: show estimates with source and unavailable state, never null as zero.
5. Confirm model assumptions with the ML teammate, especially idle-doctor queues,
   long waits and out-of-training hours/consultation counts. Replace defaults with
   properly collected data later; do not infer medical urgency from free text.
