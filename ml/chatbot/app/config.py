import os
from dataclasses import dataclass

DEFAULT_BACKEND = "https://smart-hospital-queue-management-system-production.up.railway.app"
DEFAULT_ML = "https://smart-hospital-queue-management-sys-ten.vercel.app"


@dataclass(frozen=True)
class Settings:
    backend_base_url: str
    ml_base_url: str
    queue_summary_path: str
    faq_file: str | None
    admin_api_key: str | None
    gemini_api_key: str | None
    gemini_model: str
    gemini_timeout: float
    gemini_max_calls_per_session: int
    ml_timeout: float
    request_timeout: float
    cache_ttl_seconds: float
    session_ttl_seconds: int
    cors_origins: list[str]


def load_settings() -> Settings:
    origins = os.getenv("CORS_ORIGINS", "http://localhost:5173")
    return Settings(
        backend_base_url=os.getenv("BACKEND_BASE_URL", DEFAULT_BACKEND).rstrip("/"),
        gemini_api_key=os.getenv("GEMINI_API_KEY") or None,
        gemini_model=os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite"),
        gemini_timeout=float(os.getenv("GEMINI_TIMEOUT_SECONDS", "12")),
        gemini_max_calls_per_session=int(os.getenv("GEMINI_MAX_CALLS_PER_SESSION", "20")),
        queue_summary_path=os.getenv("QUEUE_SUMMARY_PATH", "/api/doctors/{id}/queue"),
        faq_file=os.getenv("FAQ_FILE") or None,
        admin_api_key=os.getenv("ADMIN_API_KEY") or None,
        ml_base_url=os.getenv("ML_BASE_URL", DEFAULT_ML).rstrip("/"),
        ml_timeout=float(os.getenv("ML_TIMEOUT_SECONDS", "8")),
        request_timeout=float(os.getenv("REQUEST_TIMEOUT_SECONDS", "15")),
        cache_ttl_seconds=float(os.getenv("DIRECTORY_CACHE_SECONDS", "30")),
        session_ttl_seconds=int(os.getenv("SESSION_TTL_SECONDS", "1800")),
        cors_origins=[o.strip() for o in origins.split(",") if o.strip()],
    )
