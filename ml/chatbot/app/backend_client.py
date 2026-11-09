"""Async client for the Express backend.

Public routes (departments, doctors) need no login. Queue routes forward the
patient's own access token; the chatbot never stores or logs it.
"""

import time
from typing import Any

import httpx


class BackendError(Exception):
    def __init__(self, status: int, code: str, message: str = ""):
        super().__init__(f"{status} {code}: {message}")
        self.status = status
        self.code = code
        self.message = message


class BackendClient:
    PAGE_LIMIT = 50  # backend maximum
    MAX_PAGES = 10

    def __init__(
        self,
        base_url: str,
        timeout: float = 15,
        cache_ttl: float = 30,
        transport: httpx.AsyncBaseTransport | None = None,
        summary_path: str = "/api/doctors/{id}/queue",
    ):
        self._summary_path = summary_path
        self._http = httpx.AsyncClient(base_url=base_url, timeout=timeout, transport=transport)
        self._cache_ttl = cache_ttl
        self._cache: dict[str, tuple[float, Any]] = {}

    async def aclose(self) -> None:
        await self._http.aclose()

    async def _request(
        self,
        method: str,
        path: str,
        token: str | None = None,
        params: dict | None = None,
        json: dict | None = None,
    ) -> dict:
        headers = {"Authorization": f"Bearer {token}"} if token else {}
        try:
            resp = await self._http.request(method, path, params=params, json=json, headers=headers)
        except httpx.RequestError as exc:
            raise BackendError(503, "BACKEND_UNREACHABLE", type(exc).__name__) from exc

        try:
            body = resp.json()
        except ValueError:
            body = {}

        if resp.status_code >= 400 or not body.get("success", False):
            err = body.get("error") if isinstance(body, dict) else None
            if isinstance(err, dict):
                code, msg = err.get("code", "ERROR"), err.get("message", "")
            else:
                code, msg = "ERROR", str(err or "")
            raise BackendError(resp.status_code, code, msg)
        return body.get("data") or {}

    async def _paged(self, path: str, key: str) -> list[dict]:
        items: list[dict] = []
        for page in range(1, self.MAX_PAGES + 1):
            data = await self._request("GET", path, params={"page": page, "limit": self.PAGE_LIMIT})
            chunk = data.get(key, [])
            items.extend(chunk)
            if len(chunk) < self.PAGE_LIMIT:
                break
        return items

    async def _cached(self, key: str, loader) -> list[dict]:
        hit = self._cache.get(key)
        now = time.monotonic()
        if hit and hit[0] > now:
            return hit[1]
        value = await loader()
        self._cache[key] = (now + self._cache_ttl, value)
        return value

    # ---- public directory -------------------------------------------------
    async def departments(self) -> list[dict]:
        return await self._cached("departments", lambda: self._paged("/api/departments", "departments"))

    async def doctors(self) -> list[dict]:
        return await self._cached("doctors", lambda: self._paged("/api/doctors", "doctors"))

    async def queue_summary(self, doctor_id: str) -> dict:
        """Aggregate-only live queue numbers for one doctor (no patient data). Needs the backend endpoint described in
        integration/BACKEND-INTEGRATION-GUIDE.md; raises BackendError(404, NOT_FOUND) until the backend team adds it."""
        path = self._summary_path.replace("{id}", doctor_id)
        return await self._request("GET", path)

    # ---- patient queue (needs the patient's access token) -----------------
    async def my_tokens(self, token: str) -> list[dict]:
        data = await self._request("GET", "/api/queue/tokens/mine", token=token, params={"limit": 50})
        return data.get("tokens", [])

    async def token_status(self, token: str, token_id: str) -> dict:
        return await self._request("GET", f"/api/queue/tokens/{token_id}", token=token)

    async def book(self, token: str, doctor_id: str) -> dict:
        return await self._request("POST", "/api/queue/tokens", token=token, json={"doctorId": doctor_id})

    async def cancel(self, token: str, token_id: str) -> dict:
        return await self._request("PATCH", f"/api/queue/tokens/{token_id}/cancel", token=token, json={})

    # ---- ambulance requests (patient token) --------------------------------
    async def create_ambulance_request(self, token: str, address: str, lat: float, lng: float, phone: str) -> dict:
        body = {"pickupAddress": address, "latitude": lat, "longitude": lng, "contactPhone": phone}
        return await self._request("POST", "/api/ambulance-requests", token=token, json=body)

    async def my_ambulance_requests(self, token: str) -> list[dict]:
        data = await self._request("GET", "/api/ambulance-requests", token=token, params={"limit": 10})
        return data.get("requests", [])

    async def ambulance_eta(self, token: str, request_id: str) -> dict:
        return await self._request("GET", f"/api/ambulance-requests/{request_id}/eta", token=token)

    async def cancel_ambulance_request(self, token: str, request_id: str) -> dict:
        return await self._request("PATCH", f"/api/ambulance-requests/{request_id}/cancel", token=token, json={})
