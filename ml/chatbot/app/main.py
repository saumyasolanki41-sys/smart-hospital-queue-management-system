from contextlib import asynccontextmanager
from pathlib import Path

import logging
import secrets

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from .backend_client import BackendClient, BackendError
from .config import load_settings
from .engine import ChatEngine
from .faq import Faq
from .gemini_client import GeminiClient
from .ml_client import LocalML, MLClient
from .prediction.predictor import Predictor
from .prediction.routes import build_router
from .schemas import ChatRequest, ChatResponse
from .sessions import SessionStore
from .stats import Stats

STATIC = Path(__file__).parent / "static"
log = logging.getLogger("chatbot")
_LOOPBACK = {"127.0.0.1", "::1", "localhost"}
_PROXY_HEADERS = ("x-forwarded-for", "forwarded", "x-real-ip")


def _is_direct_local_request(request: Request) -> bool:
    """True only for a request that comes straight from this computer, never through a proxy."""
    client = request.client.host if request.client else ""
    return client in _LOOPBACK and not any(h in request.headers for h in _PROXY_HEADERS)


def _bearer(authorization: str | None) -> str | None:
    if authorization and authorization.lower().startswith("bearer "):
        return authorization[7:].strip() or None
    return None


def create_app(
    backend: BackendClient | None = None,
    ml: MLClient | None = None,
    gemini: GeminiClient | None = None,
    predictor: Predictor | None = None,
) -> FastAPI:
    settings = load_settings()
    client = backend or BackendClient(
        settings.backend_base_url, settings.request_timeout, settings.cache_ttl_seconds,
        summary_path=settings.queue_summary_path,
    )

    predictor = predictor or Predictor(Path(settings.models_dir))
    if ml is not None:
        ml_client = ml
    elif settings.ml_base_url:
        ml_client = MLClient(settings.ml_base_url, settings.ml_timeout)
    else:
        ml_client = LocalML(predictor)
    gemini_client = gemini
    if gemini_client is None and settings.gemini_api_key:
        gemini_client = GeminiClient(settings.gemini_api_key, settings.gemini_model, settings.gemini_timeout)
    stats = Stats()
    if settings.dev_patient_token:
        log.warning("DEV_PATIENT_TOKEN is set: local requests without a login use it. Never set it on a deployed server.")
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

    app = FastAPI(title="Smart Hospital API: predictions + chatbot", version="2.0.0", lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST"],
        allow_headers=["Authorization", "Content-Type"],
    )

    app.include_router(build_router(predictor))

    @app.get("/health", tags=["health"])
    async def health() -> dict:
        """Always 200 while the service is up (use this for the platform health check). `degraded` means a model
        failed to load; the chatbot then falls back to the backend's own estimates."""
        models = predictor.status if ml is None and not settings.ml_base_url else {"remote": await ml_client.health()}
        return {"status": "ok" if all(models.values()) else "degraded", "models": models,
                "chatbot": True, "gemini": gemini_client is not None}

    @app.get("/health/chatbot", tags=["health"])
    async def health_chatbot() -> dict:
        """Chatbot status: whether the hospital backend answers (needed for doctors, tokens, queues)."""
        try:
            await client.departments()
            reachable = True
        except BackendError as exc:  # an HTTP error reply still proves the backend is up
            reachable = exc.code != "BACKEND_UNREACHABLE"
        return {"status": "ok" if reachable else "degraded", "backend_reachable": reachable,
                "gemini_enabled": gemini_client is not None}

    @app.get("/health/gemini", tags=["health"])
    async def health_gemini() -> dict:
        """Whether the Gemini guide assistant is configured (no call is made to Google)."""
        return {"gemini_enabled": gemini_client is not None}

    @app.get("/admin/stats", include_in_schema=False)
    async def admin_stats(x_admin_key: str | None = Header(default=None)) -> dict:
        if not settings.admin_api_key:
            raise HTTPException(status_code=404)
        if not x_admin_key or not secrets.compare_digest(x_admin_key, settings.admin_api_key):
            raise HTTPException(status_code=401, detail="Invalid admin key")
        return stats.snapshot()

    @app.post("/chat", response_model=ChatResponse, tags=["chatbot"])
    async def chat(
        req: ChatRequest,
        request: Request,
        authorization: str | None = Header(default=None, include_in_schema=False),
    ) -> ChatResponse:
        
        token = _bearer(authorization)
        if not token and settings.dev_patient_token and _is_direct_local_request(request):
            token = settings.dev_patient_token
        location = (req.latitude, req.longitude) if req.latitude is not None and req.longitude is not None else None
        sess, reply = await engine.handle(req.session_id, req.message, token, req.mode, location)
        return ChatResponse(
            session_id=sess.id,
            reply=reply.text,
            intent=reply.intent,
            suggestions=reply.suggestions,
            source=reply.source,
        )


    if STATIC.is_dir():
        @app.get("/", include_in_schema=False)
        async def demo() -> FileResponse:
            return FileResponse(STATIC / "index.html")

        app.mount("/static", StaticFiles(directory=STATIC), name="static")
    else:
        @app.get("/", include_in_schema=False)
        async def root() -> dict:
            return {"service": "Smart Hospital API", "docs": "/docs"}

    return app


app = create_app()
