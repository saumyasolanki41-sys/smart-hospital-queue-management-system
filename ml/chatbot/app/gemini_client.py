

import httpx

DEFAULT_MODEL = "gemini-3.5-flash-lite"
BASE_URL = "https://generativelanguage.googleapis.com"


class GeminiError(Exception):
    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


class GeminiClient:
    def __init__(
        self,
        api_key: str,
        model: str = DEFAULT_MODEL,
        timeout: float = 12,
        max_output_tokens: int = 400,
        transport: httpx.AsyncBaseTransport | None = None,
    ):
        self._model = model
        self._max_tokens = max_output_tokens
        self._http = httpx.AsyncClient(
            base_url=BASE_URL, timeout=timeout, transport=transport,
            headers={"x-goog-api-key": api_key, "Content-Type": "application/json"},
        )

    async def aclose(self) -> None:
        await self._http.aclose()

    async def generate(self, system_prompt: str, history: list[tuple[str, str]], user_text: str) -> str:
        """history: [(role, text)] with role 'user' or 'model', oldest first."""
        contents = [{"role": r, "parts": [{"text": t}]} for r, t in history]
        contents.append({"role": "user", "parts": [{"text": user_text}]})
        body = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": contents,
            "generationConfig": {"temperature": 0.3, "maxOutputTokens": self._max_tokens},
        }
        try:
            resp = await self._http.post(f"/v1beta/models/{self._model}:generateContent", json=body)
        except httpx.TimeoutException as exc:
            raise GeminiError("timeout") from exc
        except httpx.RequestError as exc:
            raise GeminiError("unreachable") from exc

        if resp.status_code == 429:
            raise GeminiError("rate_limited")
        if resp.status_code in (401, 403):
            raise GeminiError("auth_failed")
        if resp.status_code >= 400:
            raise GeminiError(f"http_{resp.status_code}")
        try:
            data = resp.json()
        except ValueError as exc:
            raise GeminiError("malformed_response") from exc

        if (data.get("promptFeedback") or {}).get("blockReason"):
            raise GeminiError("blocked")
        cands = data.get("candidates") or []
        if not cands:
            raise GeminiError("empty")
        cand = cands[0]
        if cand.get("finishReason") in ("SAFETY", "PROHIBITED_CONTENT", "RECITATION", "SPII", "BLOCKLIST"):
            raise GeminiError("blocked")
        parts = (cand.get("content") or {}).get("parts") or []
        text = "".join(p.get("text", "") for p in parts if isinstance(p, dict)).strip()
        if not text:
            raise GeminiError("empty")
        return text
