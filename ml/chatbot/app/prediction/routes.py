"""HTTP endpoints for the two models plus a health check per model."""

from fastapi import APIRouter, HTTPException
from starlette.concurrency import run_in_threadpool

from .predictor import ModelUnavailable, PredictionFailed, Predictor, format_duration
from .schemas import AmbulanceInput, QueueInput


def build_router(predictor: Predictor) -> APIRouter:
    router = APIRouter()

    def _check(name: str) -> dict:
        loaded = predictor.status[name]
        if not loaded:
            raise HTTPException(status_code=503, detail=f"{name.capitalize()} model is not loaded.")
        return {"status": "ok", "model": name, "loaded": True}

    @router.get("/health/queue-model", tags=["health"])
    def health_queue_model() -> dict:
        """200 when the queue wait-time model is loaded, 503 otherwise."""
        return _check("queue")

    @router.get("/health/ambulance-model", tags=["health"])
    def health_ambulance_model() -> dict:
        """200 when the ambulance ETA model is loaded, 503 otherwise."""
        return _check("ambulance")

    @router.post("/predict/queue-time", tags=["prediction"])
    async def predict_queue(data: QueueInput) -> dict:
        try:
            minutes = round(await run_in_threadpool(predictor.queue_minutes, data), 2)
        except ModelUnavailable as exc:
            raise HTTPException(status_code=503, detail=str(exc))
        except PredictionFailed as exc:
            raise HTTPException(status_code=400, detail=str(exc))
        formatted = format_duration(minutes)
        return {"wait_time": formatted, "wait_time_minutes": minutes}

    @router.post("/predict/ambulance-eta", tags=["prediction"])
    async def predict_ambulance(data: AmbulanceInput) -> dict:
        try:
            minutes = round(await run_in_threadpool(predictor.ambulance_minutes, data), 2)
        except ModelUnavailable as exc:
            raise HTTPException(status_code=503, detail=str(exc))
        except PredictionFailed as exc:
            raise HTTPException(status_code=400, detail=str(exc))
        return {"ambulance": format_duration(minutes), "eta_minutes": minutes}

    return router
