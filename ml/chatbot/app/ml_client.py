"""Client for the hospital prediction API (the `ML` branch: ml/main.py).

Endpoints used:
  POST /predict/queue-time    -> {"wait_time ": {"formatted": "23 min 24 sec"}}   (note the trailing space in the key)
  POST /predict/ambulance-eta -> {"ambulance": {"formatted": "9 min 05 sec"}}
  GET  /health

Every failure becomes an MLError so callers can fall back to the backend's own estimate.
"""

import re
from datetime import datetime
from typing import Any
from zoneinfo import ZoneInfo

import httpx

IST = ZoneInfo("Asia/Kolkata")

# Exact values accepted by the ML service's QueueInput.Specialty
ML_SPECIALTIES = [
    "Cardiology", "Dermatology", "Gastroenterology", "General Medicine", "Internal Medicine",
    "Neurology", "Obstetrics & Gynecology", "Orthopedics", "Pediatrics", "Psychiatry",
]

_ALIASES = {
    "paediatrics": "Pediatrics", "pediatric": "Pediatrics", "paediatric": "Pediatrics", "child health": "Pediatrics",
    "obstetrics and gynecology": "Obstetrics & Gynecology", "obstetrics gynecology": "Obstetrics & Gynecology",
    "obstetrics and gynaecology": "Obstetrics & Gynecology", "obstetrics gynaecology": "Obstetrics & Gynecology",
    "obgyn": "Obstetrics & Gynecology", "ob gyn": "Obstetrics & Gynecology", "gynecology": "Obstetrics & Gynecology",
    "gynaecology": "Obstetrics & Gynecology", "orthopaedics": "Orthopedics", "orthopedic": "Orthopedics",
    "orthopaedic": "Orthopedics", "gastro": "Gastroenterology", "general physician": "General Medicine",
    "general medicine": "General Medicine", "psychiatric": "Psychiatry", "mental health": "Psychiatry",
    "neurological": "Neurology", "dermatologist": "Dermatology", "cardiologist": "Cardiology",
}


def _norm(text: str) -> str:
    return re.sub(r"[^a-z0-9& ]+", " ", (text or "").lower().replace("&", " and ")).replace("  ", " ").strip()


def map_specialty(*names: str | None) -> str | None:
    """Map a department / specialization name to an ML specialty, or None if the model has no match
    (the caller then keeps the backend's own estimate)."""
    lookup = {_norm(s): s for s in ML_SPECIALTIES}
    for name in names:
        n = _norm(name or "")
        if not n:
            continue
        if n in lookup:
            return lookup[n]
        if n in _ALIASES:
            return _ALIASES[n]
        for key, spec in {**lookup, **_ALIASES}.items():
            if key and re.search(rf"\b{re.escape(key)}\b", n):
                return spec if isinstance(spec, str) else lookup[key]
    return None


class MLError(Exception):
    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


_DURATION = re.compile(r"(\d+)\s*min\s*(\d+)\s*sec", re.I)


def parse_minutes(payload: Any, key: str) -> float:
    """Extract minutes from `{key: {"formatted": "M min SS sec"}}`, tolerating stray whitespace in the key."""
    if not isinstance(payload, dict):
        raise MLError("malformed_response")
    value = next((v for k, v in payload.items() if isinstance(k, str) and k.strip() == key), None)
    if isinstance(value, (int, float)):
        return float(value)
    text = value.get("formatted") if isinstance(value, dict) else value
    m = _DURATION.search(text) if isinstance(text, str) else None
    if not m:
        raise MLError("malformed_response")
    return int(m.group(1)) + int(m.group(2)) / 60.0


def ist_now() -> datetime:
    return datetime.now(IST)


class MLClient:
    def __init__(self, base_url: str, timeout: float = 8, transport: httpx.AsyncBaseTransport | None = None):
        # Vercel/Render cold starts can be slow, so the default is more generous than the backend's 4 s.
        self._http = httpx.AsyncClient(base_url=base_url, timeout=timeout, transport=transport)

    async def aclose(self) -> None:
        await self._http.aclose()

    async def _post(self, path: str, body: dict) -> dict:
        last: MLError | None = None
        for _ in range(2):  # one retry, only for network errors and 5xx
            try:
                resp = await self._http.post(path, json=body)
            except httpx.TimeoutException:
                last = MLError("timeout")
                continue
            except httpx.RequestError:
                last = MLError("unreachable")
                continue
            if resp.status_code >= 500:
                last = MLError("service_unavailable")
                continue
            if resp.status_code >= 400:
                raise MLError("rejected_input")  # 4xx: retrying will not help
            try:
                return resp.json()
            except ValueError:
                raise MLError("malformed_response")
        raise last or MLError("unreachable")

    async def health(self) -> bool:
        try:
            resp = await self._http.get("/health")
            return resp.status_code == 200
        except httpx.RequestError:
            return False

    async def predict_queue(
        self,
        specialty: str,
        people_ahead: int,
        avg_consult_min: float,
        now: datetime | None = None,
    ) -> float:
        """Minutes a patient with `people_ahead` waiting patients in front should expect to wait.

        Assumptions (same as the backend's ML integration): standard complexity, follow-up visit,
        no urgency. The patient-facing API doesn't expose the current consultation's elapsed time,
        so the doctor is treated as busy whenever somebody is ahead.
        """
        now = now or ist_now()
        avg = max(float(avg_consult_min), 1.0)
        busy = 1 if people_ahead > 0 else 0
        body = {
            "Specialty": specialty,
            "Hour": now.hour,
            "Day_Of_Week": now.weekday(),  # Monday = 0, as in the training data
            "Doctor_Avg_Consult_Min": avg,
            "Issue_Complexity": "Standard",
            "Visit_Type": "Follow-up",
            "Is_Urgent": 0,
            "Patients_Waiting": people_ahead,
            "Waiting_Standard": people_ahead,
            "Doctor_Busy": busy,
            "Current_Issue_Complexity": "Standard" if busy else "None",
            "Current_Consult_Elapsed_Min": 0.0,
            # In the training data, expected work is ~ waiting patients x the doctor's average.
            "Queue_Expected_Work_Min": round(people_ahead * avg * 0.98, 2),
        }
        return parse_minutes(await self._post("/predict/queue-time", body), "wait_time")

    async def predict_ambulance(
        self,
        distance_km: float,
        traffic_level: int = 2,
        weather_severity: int = 0,
        region: str = "Urban",
        road: str = "Local Road",
        emergency_level: str = "Minor",
        now: datetime | None = None,
    ) -> float:
        now = now or ist_now()
        body = {
            "Hour": now.hour,
            "Traffic_Level": traffic_level,
            "Weather_Severity": weather_severity,
            "Weather_Impact_Level": weather_severity,
            "Distance_to_Incident": distance_km,
            "Ambulance_Speed": 40.0,
            "Region_Type": region,
            "Road_Type": road,
            "Emergency_Level": emergency_level,
        }
        return parse_minutes(await self._post("/predict/ambulance-eta", body), "ambulance")
