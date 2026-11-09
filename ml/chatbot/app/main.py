from contextlib import asynccontextmanager
from pathlib import Path

import secrets

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from .backend_client import BackendClient
from .config import load_settings
from .engine import ChatEngine
from .faq import Faq
from .gemini_client import GeminiClient
from .ml_client import MLClient
from .schemas import ChatRequest, ChatResponse
from .sessions import SessionStore
from .stats import Stats

STATIC = Path(__file__).parent / "static"


def _bearer(authorization: str | None) -> str | None:
    if authorization and authorization.lower().startswith("bearer "):
        return authorization[7:].strip() or None
    return None


def create_app(
    backend: BackendClient | None = None,
    ml: MLClient | None = None,
    gemini: GeminiClient | None = None,
) -> FastAPI:
    settings = load_settings()
    client = backend or BackendClient(
        settings.backend_base_url, settings.request_timeout, settings.cache_ttl_seconds,
        summary_path=settings.queue_summary_path,
    )
    ml_client = ml or MLClient(settings.ml_base_url, settings.ml_timeout)
    gemini_client = gemini
    if gemini_client is None and settings.gemini_api_key:
        gemini_client = GeminiClient(settings.gemini_api_key, settings.gemini_model, settings.gemini_timeout)
    stats = Stats()
    engine = ChatEngine(client, SessionStore(settings.session_ttl_seconds), ml_client,
                        gemini_client, settings.gemini_max_calls_per_session,
                        faq=Faq.load(settings.faq_file), stats=stats)

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        yield
        await client.aclose()
        await ml_client.aclose()
        if gemini_client:
            await gemini_client.aclose()

    app = FastAPI(title="Smart Hospital Queue Chatbot", version="1.0.0", lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST"],
        allow_headers=["Authorization", "Content-Type"],
    )

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok"}

    @app.get("/health/ml")
    async def health_ml() -> dict:
        """Whether the prediction API is reachable. The chatbot keeps working without it (falls back)."""
        return {"ml_available": await ml_client.health()}

    @app.get("/health/gemini")
    async def health_gemini() -> dict:
        """Whether the Gemini guide assistant is configured (no call is made to Google)."""
        return {"gemini_enabled": gemini_client is not None}

    @app.get("/admin/stats", include_in_schema=False)
    async def admin_stats(x_admin_key: str | None = Header(default=None)) -> dict:
        """Anonymous usage counters (common inquiries, fallbacks). Disabled unless ADMIN_API_KEY is set."""
        if not settings.admin_api_key:
            raise HTTPException(status_code=404)
        if not x_admin_key or not secrets.compare_digest(x_admin_key, settings.admin_api_key):
            raise HTTPException(status_code=401, detail="Invalid admin key")
        return stats.snapshot()

    @app.post("/chat", response_model=ChatResponse)
    async def chat(req: ChatRequest, authorization: str | None = Header(default=None)) -> ChatResponse:
        """Send a message. Pass the patient's backend access token as
        `Authorization: Bearer <token>` to enable booking, status and cancellation."""
        location = (req.latitude, req.longitude) if req.latitude is not None and req.longitude is not None else None
        sess, reply = await engine.handle(req.session_id, req.message, _bearer(authorization), req.mode, location)
        return ChatResponse(
            session_id=sess.id,
            reply=reply.text,
            intent=reply.intent,
            suggestions=reply.suggestions,
            requires_login=reply.requires_login,
            source=reply.source,
        )

    @app.get("/", include_in_schema=False)
    async def demo() -> FileResponse:
        return FileResponse(STATIC / "index.html")

    app.mount("/static", StaticFiles(directory=STATIC), name="static")
    return app


app = create_app()
