from typing import Literal

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    session_id: str | None = Field(
        default=None,
        max_length=64,
        description="Omit on the first message; send back the value returned by the server afterwards.",
    )
    mode: Literal["auto", "rules"] = Field(
        default="auto",
        description="auto: the intent bot answers what it understands and Gemini answers the rest. "
                    "rules: intent bot only (Gemini never called).",
    )
    latitude: float | None = Field(default=None, ge=-90, le=90, description="Optional device location, used for ambulance requests.")
    longitude: float | None = Field(default=None, ge=-180, le=180)


class ChatResponse(BaseModel):
    session_id: str
    reply: str
    intent: str
    suggestions: list[str] = []
    requires_login: bool = False
    source: Literal["rules", "gemini", "fallback"] = "rules"
