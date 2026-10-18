from pathlib import Path
import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


app = FastAPI()


BASE_DIR = Path(__file__).resolve().parent


try:
    ambulance_model = joblib.load(BASE_DIR / "ambulance-eta" / "ambulance_pipeline.pkl")
    queue_model = joblib.load(BASE_DIR / "queue_time" / "queue_pipeline.pkl")
except Exception as e:
    print(f"Error loading models: {e}")
    ambulance_model = None
    queue_model = None



class AmbulanceInput(BaseModel):
    Hour: float
    Traffic_Level: float
    Weather_Severity: float
    Weather_Impact_Level: float
    Distance_to_Incident: float
    Ambulance_Speed: float
    Region_Type: str
    Road_Type: str
    Emergency_Level: str
    Is_Human_Dispatch: float = 1.0


class QueueInput(BaseModel):
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
    Waiting_Short: int = 0
    Waiting_Standard: int = 0
    Waiting_Long: int = 0
    Waiting_New: int = 0
    Waiting_Urgent: int = 0
    Doctor_Busy: int = 1
    Current_Issue_Complexity: str = "Standard"
    Current_Consult_Elapsed_Min: float = 0.0
    Queue_Expected_Work_Min: float = 0.0



@app.get("/health")
def health():
    if ambulance_model is None or queue_model is None:
        return {"status": "error", "message": "Models not loaded"}
    return {"status": "ok", "message": "Both models are ready"}


@app.post("/predict/ambulance-eta")
def predict_ambulance(data: AmbulanceInput):
    if ambulance_model is None:
        raise HTTPException(status_code=500, detail="Ambulance model is not available")

    input_data = data.model_dump()


    hour = input_data["Hour"]
    input_data["Is_Rush_Hour"] = 1 if (8.0 <= hour <= 10.0 or 17.0 <= hour <= 19.0) else 0
    input_data["Is_Night"] = 1 if (hour >= 22.0 or hour < 6.0) else 0


    dist = input_data["Distance_to_Incident"]
    speed = input_data["Ambulance_Speed"]
    if speed <= 0:
        raise HTTPException(status_code=400, detail="Ambulance_Speed must be greater than zero")
    input_data["Base_Travel_Time_Min"] = round((dist / speed) * 60.0, 2)
    input_data["Traffic_x_Distance"] = round(input_data["Traffic_Level"] * dist, 2)
    input_data["Weather_x_Distance"] = round(input_data["Weather_Severity"] * dist, 2)


    df = pd.DataFrame([input_data])


    prediction = ambulance_model.predict(df)
    return {"eta_minutes": round(float(prediction[0]), 2)}


@app.post("/predict/queue-time")
def predict_queue(data: QueueInput):
    if queue_model is None:
        raise HTTPException(status_code=500, detail="Queue model is not available")

    input_data = data.model_dump()

    df = pd.DataFrame([input_data])

    prediction = queue_model.predict(df)
    return {"wait_time_minutes": round(float(prediction[0]), 2)}