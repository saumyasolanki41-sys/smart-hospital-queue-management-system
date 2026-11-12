"""Request models for the prediction endpoints. Field names, ranges and defaults are identical to the original
ml/main.py so existing callers (backend ml.service.js, the chatbot) keep working unchanged."""

from typing import Literal

from pydantic import BaseModel, Field


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
        "Cardiology", "Dermatology", "Gastroenterology", "General Medicine", "Internal Medicine",
        "Neurology", "Obstetrics & Gynecology", "Orthopedics", "Pediatrics", "Psychiatry",
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
