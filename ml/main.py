from pathlib import Path
from typing import Literal
import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Hospital & Ambulance Prediction API")

BASE_DIR = Path(__file__).resolve().parent


AMBULANCE_FEATURES = [
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
]

QUEUE_FEATURES = [
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
]


try:
    ambulance_model = joblib.load(BASE_DIR / "ambulance-eta" / "ambulance_pipeline.pkl")
    queue_model = joblib.load(BASE_DIR / "queue_time" / "queue_pipeline.pkl")
except Exception as e:
    print(f"Error loading models: {e}")
    ambulance_model = None
    queue_model = None




class AmbulanceInput(BaseModel):
    Hour: float = Field(..., ge=0.0, le=23.0)
    Traffic_Level: float = Field(..., ge=1.0, le=3.0)
    Weather_Severity: float = Field(default=0.0, ge=0.0, le=2.0)
    Weather_Impact_Level: float = Field(default=0.0, ge=0.0, le=2.0)
    Distance_to_Incident: float = Field(..., gt=0.0)
    Ambulance_Speed: float = Field(default=40.0, gt=0.0)
    Region_Type: Literal["Urban", "Suburban", "Rural"] = "Urban"
    Road_Type: Literal["Highway", "Local Road", "Unpaved Road"] = "Local Road"
    Emergency_Level: Literal["Minor", "Major", "Critical"] = "Minor"
    Is_Human_Dispatch: float = 1.0


class QueueInput(BaseModel):
    Specialty: Literal[
        "Cardiology",
        "Dermatology",
        "Gastroenterology",
        "General Medicine",
        "Internal Medicine",
        "Neurology",
        "Obstetrics & Gynecology",
        "Orthopedics",
        "Pediatrics",
        "Psychiatry",
    ]
    Hour: int = Field(..., ge=0, le=23)
    Day_Of_Week: int = Field(..., ge=0, le=6)
    Doctor_Avg_Consult_Min: float = Field(..., gt=0.0)
    Doctor_Consults_Logged: int = Field(default=500, ge=0)
    Ref_Median_Consult_Min: float = Field(default=12.0, gt=0.0)
    Issue_Complexity: Literal["Short", "Standard", "Long"] = "Standard"
    Visit_Type: Literal["New", "Follow-up"] = "Follow-up"
    Is_Urgent: int = Field(default=0, ge=0, le=1)
    Patients_Waiting: int = Field(default=0, ge=0)
    Waiting_Short: int = 0
    Waiting_Standard: int = 0
    Waiting_Long: int = 0
    Waiting_New: int = 0
    Waiting_Urgent: int = 0
    Doctor_Busy: int = 1
    Current_Issue_Complexity: Literal["None", "Short", "Standard", "Long"] = "Standard"
    Current_Consult_Elapsed_Min: float = 0.0
    Queue_Expected_Work_Min: float = 0.0


# --- Endpoints ---

@app.get("/health")
def health():
    if ambulance_model is None or queue_model is None:
        raise HTTPException(status_code=503, detail="Prediction models are not loaded.")
    return {
        "status": "ok",
        "models": {
            "ambulance": ambulance_model is not None,
            "queue": queue_model is not None,
        },
    }


@app.post("/predict/ambulance-eta")
def predict_ambulance(data: AmbulanceInput):
    if ambulance_model is None:
        raise HTTPException(status_code=503, detail="Ambulance model is not available.")

    input_data = data.model_dump()

    hour = input_data["Hour"]
    input_data["Is_Rush_Hour"] = 1 if (8.0 <= hour <= 10.0 or 17.0 <= hour <= 19.0) else 0
    input_data["Is_Night"] = 1 if (hour >= 22.0 or hour < 6.0) else 0

    dist = input_data["Distance_to_Incident"]
    speed = input_data["Ambulance_Speed"]
    input_data["Base_Travel_Time_Min"] = round((dist / speed) * 60.0, 2)
    input_data["Traffic_x_Distance"] = round(input_data["Traffic_Level"] * dist, 2)
    input_data["Weather_x_Distance"] = round(input_data["Weather_Severity"] * dist, 2)

    try:

        df = pd.DataFrame([input_data])[AMBULANCE_FEATURES]
        prediction = ambulance_model.predict(df)
        eta = max(1.0, float(prediction[0]))  
        return {"eta_minutes": round(eta, 2)}
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Prediction failed: {str(exc)}")


@app.post("/predict/queue-time")
def predict_queue(data: QueueInput):
    if queue_model is None:
        raise HTTPException(status_code=503, detail="Queue model is not available.")

    input_data = data.model_dump()

    numeric_columns = [
        "Hour",
        "Day_Of_Week",
        "Doctor_Avg_Consult_Min",
        "Doctor_Consults_Logged",
        "Ref_Median_Consult_Min",
        "Is_Urgent",
        "Patients_Waiting",
        "Waiting_Short",
        "Waiting_Standard",
        "Waiting_Long",
        "Waiting_New",
        "Waiting_Urgent",
        "Doctor_Busy",
        "Current_Consult_Elapsed_Min",
        "Queue_Expected_Work_Min",
    ]

    try:
        df = pd.DataFrame([input_data])[QUEUE_FEATURES]
        df[numeric_columns] = df[numeric_columns].astype(float)

        prediction = queue_model.predict(df)
        wait_time = max(0.0, float(prediction[0])) 
        return {"wait_time_minutes": round(wait_time, 2)}
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Prediction failed: {str(exc)}")