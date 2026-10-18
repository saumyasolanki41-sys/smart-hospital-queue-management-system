import logging
from pathlib import Path

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict


logger = logging.getLogger(__name__)
BASE_DIR = Path(__file__).resolve().parent

AMBULANCE_FEATURES = (
    "Hour",
    "Is_Rush_Hour",
    "Is_Night",
    "Traffic_Level",
    "Weather_Severity",
    "Weather_Impact_Level",
    "Distance_to_Incident",
    "Ambulance_Speed",
    "Base_Travel_Time_Min",
    "Traffic_x_Distance",
    "Weather_x_Distance",
    "Is_Human_Dispatch",
    "Region_Type",
    "Road_Type",
    "Emergency_Level",
)

QUEUE_FEATURES = (
    "Specialty",
    "Hour",
    "Day_Of_Week",
    "Doctor_Avg_Consult_Min",
    "Doctor_Consults_Logged",
    "Ref_Median_Consult_Min",
    "Issue_Complexity",
    "Visit_Type",
    "Is_Urgent",
    "Patients_Waiting",
    "Waiting_Short",
    "Waiting_Standard",
    "Waiting_Long",
    "Waiting_New",
    "Waiting_Urgent",
    "Doctor_Busy",
    "Current_Issue_Complexity",
    "Current_Consult_Elapsed_Min",
    "Queue_Expected_Work_Min",
)


class AmbulanceInput(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [
                {
                    "Hour": 14.0,
                    "Is_Rush_Hour": 0,
                    "Is_Night": 0,
                    "Traffic_Level": 2.0,
                    "Weather_Severity": 0.0,
                    "Weather_Impact_Level": 0.0,
                    "Distance_to_Incident": 12.5,
                    "Ambulance_Speed": 48.0,
                    "Base_Travel_Time_Min": 15.6,
                    "Traffic_x_Distance": 25.0,
                    "Weather_x_Distance": 0.0,
                    "Is_Human_Dispatch": 1.0,
                    "Region_Type": "Urban",
                    "Road_Type": "Local Road",
                    "Emergency_Level": "Major",
                }
            ]
        },
    )

    Hour: float
    Is_Rush_Hour: int
    Is_Night: int
    Traffic_Level: float
    Weather_Severity: float
    Weather_Impact_Level: float
    Distance_to_Incident: float
    Ambulance_Speed: float
    Base_Travel_Time_Min: float
    Traffic_x_Distance: float
    Weather_x_Distance: float
    Is_Human_Dispatch: float
    Region_Type: str
    Road_Type: str
    Emergency_Level: str


class QueueInput(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [
                {
                    "Specialty": "Pediatrics",
                    "Hour": 13,
                    "Day_Of_Week": 5,
                    "Doctor_Avg_Consult_Min": 11.38,
                    "Doctor_Consults_Logged": 845,
                    "Ref_Median_Consult_Min": 10.2,
                    "Issue_Complexity": "Standard",
                    "Visit_Type": "New",
                    "Is_Urgent": 0,
                    "Patients_Waiting": 1,
                    "Waiting_Short": 1,
                    "Waiting_Standard": 0,
                    "Waiting_Long": 0,
                    "Waiting_New": 0,
                    "Waiting_Urgent": 0,
                    "Doctor_Busy": 1,
                    "Current_Issue_Complexity": "Standard",
                    "Current_Consult_Elapsed_Min": 13.46,
                    "Queue_Expected_Work_Min": 12.66,
                }
            ]
        },
    )

    Specialty: str
    Hour: int
    Day_Of_Week: int
    Doctor_Avg_Consult_Min: float
    Doctor_Consults_Logged: int
    Ref_Median_Consult_Min: float
    Issue_Complexity: str
    Visit_Type: str
    Is_Urgent: int
    Patients_Waiting: int
    Waiting_Short: int
    Waiting_Standard: int
    Waiting_Long: int
    Waiting_New: int
    Waiting_Urgent: int
    Doctor_Busy: int
    Current_Issue_Complexity: str
    Current_Consult_Elapsed_Min: float
    Queue_Expected_Work_Min: float


class AmbulancePrediction(BaseModel):
    eta_minutes: float


class QueuePrediction(BaseModel):
    wait_time_minutes: float


class HealthResponse(BaseModel):
    status: str
    models: dict[str, bool]


AMBULANCE_MODEL = joblib.load(BASE_DIR / "ambulance-eta" / "ambulance_pipeline.pkl")
QUEUE_MODEL = joblib.load(BASE_DIR / "queue_time" / "queue_pipeline.pkl")

app = FastAPI(title="Smart Hospital Prediction API", version="1.0.0")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    model_status = {
        "ambulance": AMBULANCE_MODEL is not None,
        "queue": QUEUE_MODEL is not None,
    }
    if not all(model_status.values()):
        raise HTTPException(status_code=503, detail="Prediction models are unavailable.")
    return HealthResponse(status="ok", models=model_status)


@app.post("/predict/ambulance-eta", response_model=AmbulancePrediction)
def predict_ambulance(
    payload: AmbulanceInput,
) -> AmbulancePrediction:
    try:
        input_frame = pd.DataFrame([payload.model_dump()], columns=AMBULANCE_FEATURES)
        prediction = AMBULANCE_MODEL.predict(input_frame)
        return AmbulancePrediction(eta_minutes=float(prediction[0]))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid ambulance prediction input.") from exc
    except Exception as exc:
        logger.exception("Ambulance ETA prediction failed")
        raise HTTPException(status_code=500, detail="Ambulance ETA prediction failed.") from exc


@app.post("/predict/queue-time", response_model=QueuePrediction)
def predict_queue_time(
    payload: QueueInput,
) -> QueuePrediction:
    try:
        input_frame = pd.DataFrame([payload.model_dump()], columns=QUEUE_FEATURES)
        prediction = QUEUE_MODEL.predict(input_frame)
        return QueuePrediction(wait_time_minutes=float(prediction[0]))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid queue prediction input.") from exc
    except Exception as exc:
        logger.exception("Queue wait-time prediction failed")
        raise HTTPException(status_code=500, detail="Queue wait-time prediction failed.") from exc