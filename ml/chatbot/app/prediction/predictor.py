
import logging
from pathlib import Path

from .schemas import AmbulanceInput, QueueInput

log = logging.getLogger("prediction")

AMBULANCE_FEATURES = [
    "Hour", "Is_Rush_Hour", "Is_Night", "Traffic_Level", "Weather_Severity", "Weather_Impact_Level",
    "Distance_to_Incident", "Ambulance_Speed", "Base_Travel_Time_Min", "Traffic_x_Distance",
    "Weather_x_Distance", "Is_Human_Dispatch", "Region_Type", "Road_Type", "Emergency_Level",
]

QUEUE_FEATURES = [
    "Specialty", "Hour", "Day_Of_Week", "Doctor_Avg_Consult_Min", "Doctor_Consults_Logged",
    "Ref_Median_Consult_Min", "Issue_Complexity", "Visit_Type", "Is_Urgent", "Patients_Waiting",
    "Waiting_Short", "Waiting_Standard", "Waiting_Long", "Waiting_New", "Waiting_Urgent", "Doctor_Busy",
    "Current_Issue_Complexity", "Current_Consult_Elapsed_Min", "Queue_Expected_Work_Min",
]

_QUEUE_NUMERIC = [
    "Hour", "Day_Of_Week", "Doctor_Avg_Consult_Min", "Doctor_Consults_Logged", "Ref_Median_Consult_Min",
    "Is_Urgent", "Patients_Waiting", "Waiting_Short", "Waiting_Standard", "Waiting_Long", "Waiting_New",
    "Waiting_Urgent", "Doctor_Busy", "Current_Consult_Elapsed_Min", "Queue_Expected_Work_Min",
]


class ModelUnavailable(Exception):
    """The requested model file is not loaded."""


class PredictionFailed(Exception):
    """The model rejected the input."""


def format_duration(total_minutes: float) -> dict:
    hours, minutes = divmod(round(total_minutes), 60)
    parts = []
    if hours:
        parts.append(f"{hours} {'hour' if hours == 1 else 'hours'}")
    if minutes or not hours:
        parts.append(f"{minutes} {'minute' if minutes == 1 else 'minutes'}")
    return {"formatted": " ".join(parts)}


class Predictor:
    def __init__(self, models_dir: Path):
        self.models_dir = Path(models_dir)
        self.ambulance_model = self._load("ambulance_pipeline.pkl")
        self.queue_model = self._load("queue_pipeline.pkl")

    def _load(self, relative: str):
        path = self.models_dir / relative
        try:
            import joblib  # imported lazily so the chatbot can run (tests, no models) without scikit-learn
            model = joblib.load(path)
            log.info("Loaded model %s", path)
            return model
        except Exception as exc:  # missing file, version mismatch, corrupt pickle
            log.error("Could not load model %s: %s", path, exc)
            return None

    @property
    def status(self) -> dict:
        return {"queue": self.queue_model is not None, "ambulance": self.ambulance_model is not None}

    def queue_minutes(self, data: QueueInput) -> float:
        if self.queue_model is None:
            raise ModelUnavailable("Queue model is not available.")
        import pandas as pd
        try:
            df = pd.DataFrame([data.model_dump()])[QUEUE_FEATURES]
            df[_QUEUE_NUMERIC] = df[_QUEUE_NUMERIC].astype(float)
            return max(0.0, float(self.queue_model.predict(df)[0]))
        except Exception as exc:
            raise PredictionFailed(f"Prediction failed: {exc}") from exc

    def ambulance_minutes(self, data: AmbulanceInput) -> float:
        if self.ambulance_model is None:
            raise ModelUnavailable("Ambulance model is not available.")
        import pandas as pd
        row = data.model_dump()
        hour = row["Hour"]
        row["Is_Rush_Hour"] = 1 if (8.0 <= hour <= 10.0 or 17.0 <= hour <= 19.0) else 0
        row["Is_Night"] = 1 if (hour >= 22.0 or hour < 6.0) else 0
        dist, speed = row["Distance_to_Incident"], row["Ambulance_Speed"]
        row["Base_Travel_Time_Min"] = round((dist / speed) * 60.0, 2)
        row["Traffic_x_Distance"] = round(row["Traffic_Level"] * dist, 2)
        row["Weather_x_Distance"] = round(row["Weather_Severity"] * dist, 2)
        try:
            df = pd.DataFrame([row])[AMBULANCE_FEATURES]
            return max(1.0, float(self.ambulance_model.predict(df)[0]))
        except Exception as exc:
            raise PredictionFailed(f"Prediction failed: {exc}") from exc
