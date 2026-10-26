
import re
import difflib
from datetime import datetime
from pathlib import Path
from typing import Literal, Optional

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline

app = FastAPI(title="Hospital Chatbot & Prediction API")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

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


def run_ambulance_model(data: AmbulanceInput) -> float:
    """Your ambulance logic, moved into a function so the chatbot can call it too."""
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
        return round(eta, 2)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Prediction failed: {str(exc)}")


QUEUE_NUMERIC_COLUMNS = [
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


def run_queue_model(data: QueueInput) -> float:
    """Your queue logic, moved into a function so the chatbot can call it too."""
    if queue_model is None:
        raise HTTPException(status_code=503, detail="Queue model is not available.")

    input_data = data.model_dump()

    try:
        df = pd.DataFrame([input_data])[QUEUE_FEATURES]
        df[QUEUE_NUMERIC_COLUMNS] = df[QUEUE_NUMERIC_COLUMNS].astype(float)

        prediction = queue_model.predict(df)
        wait_time = max(0.0, float(prediction[0]))
        return round(wait_time, 2)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Prediction failed: {str(exc)}")


def split_duration(minutes: float) -> dict:
    """6.84 minutes -> {"minutes": 6, "seconds": 50}"""
    total_seconds = round(minutes * 60)
    mins, secs = divmod(total_seconds, 60)
    return {"minutes": mins, "seconds": secs}


def format_duration(minutes: float) -> str:
    """6.84 minutes -> '6 min 50 sec'"""
    d = split_duration(minutes)
    return f"{d['minutes']} min {d['seconds']} sec"


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
    eta = run_ambulance_model(data)
    return {
        "eta_minutes": eta,              
        "eta": format_duration(eta),     
        **split_duration(eta),           
    }


@app.post("/predict/queue-time")
def predict_queue(data: QueueInput):
    wait = run_queue_model(data)
    return {
        "wait_time_minutes": wait,           
        "wait_time": format_duration(wait),  
        **split_duration(wait),              
    }


DOCTORS = {
    "Cardiology": [
        {"id": 1, "name": "Dr. Sharma", "avg_consult_min": 14.0},
        {"id": 2, "name": "Dr. Mehta", "avg_consult_min": 12.0},
    ],
    "Dermatology": [{"id": 3, "name": "Dr. Verma", "avg_consult_min": 9.0}],
    "Gastroenterology": [{"id": 4, "name": "Dr. Iyer", "avg_consult_min": 13.0}],
    "General Medicine": [{"id": 5, "name": "Dr. Khan", "avg_consult_min": 10.0}],
    "Internal Medicine": [{"id": 6, "name": "Dr. Joshi", "avg_consult_min": 12.0}],
    "Neurology": [{"id": 7, "name": "Dr. Nair", "avg_consult_min": 16.0}],
    "Obstetrics & Gynecology": [{"id": 8, "name": "Dr. Kapoor", "avg_consult_min": 15.0}],
    "Orthopedics": [{"id": 9, "name": "Dr. Singh", "avg_consult_min": 11.0}],
    "Pediatrics": [
        {"id": 10, "name": "Dr. Gupta", "avg_consult_min": 10.0},
        {"id": 11, "name": "Dr. Rao", "avg_consult_min": 11.0},
    ],
    "Psychiatry": [{"id": 12, "name": "Dr. Bose", "avg_consult_min": 20.0}],
}


DEPT_KEYWORDS = {
    "Cardiology": ["cardio", "heart"],
    "Dermatology": ["dermat", "skin"],
    "Gastroenterology": ["gastro", "stomach"],
    "General Medicine": ["general", "physician"],
    "Internal Medicine": ["internal"],
    "Neurology": ["neuro", "brain"],
    "Obstetrics & Gynecology": ["gynec", "gynaec", "obstetric", "pregnan", "obgyn", "ob-gyn"],
    "Orthopedics": ["ortho", "bone", "joint"],
    "Pediatrics": ["pediatric", "paediatric", "child", "kids", "baby"],
    "Psychiatry": ["psychiatr", "mental health"],
}


DOCTOR_STATUS = {
    1: {"complexity": "Standard", "elapsed_min": 6.0},
    10: {"complexity": "Short", "elapsed_min": 3.0},
}


COMPLEXITY_MIN = {"Short": 6.0, "Standard": 12.0, "Long": 20.0}

TOKENS = {}       
NEXT_TOKEN = [1]
SESSIONS = {}     

FAQS = {
    "what are the opd timings": "OPD is open Monday to Saturday, 9:00 AM to 5:00 PM.",
    "what is the consultation fee": "General consultation is Rs. 300, specialist consultation is Rs. 600.",
    "what documents should i bring": "Please bring a photo ID, previous prescriptions and reports, and your insurance card if any.",
    "visiting hours": "Visiting hours are 4:00 PM to 6:00 PM daily.",
    "where is the hospital located": "We are at Main Road, Sector 5. Reception is on the ground floor.",
    "is there parking": "Yes, free parking is available for patients and visitors.",
    "do you accept insurance": "Yes, we accept most major insurance providers. Please carry your card.",
    "ambulance number": "Our 24x7 ambulance number is 102 / 108.",
}

TRAIN = {
    "greeting": ["hi", "hello", "hey", "good morning", "namaste", "hii"],
    "book_token": [
        "book a token", "i want an appointment", "book appointment with doctor",
        "need a token for tomorrow", "token chahiye", "doctor se milna hai",
        "i want to see a cardiologist", "get me a token", "appointment book karo",
    ],
    "check_queue": [
        "check my token status", "what is the queue status", "how long is the wait",
        "which token is running", "mera token kab aayega", "my turn kab hai",
        "queue status", "waiting time", "how long will i wait",
    ],
    "cancel_token": [
        "cancel my token", "cancel appointment", "i want to cancel booking",
        "token cancel karo", "remove my appointment",
    ],
    "ambulance": [
        "how long will the ambulance take", "ambulance eta", "ambulance kitni der mein aayegi",
        "when will ambulance arrive", "i need an ambulance", "estimate ambulance arrival time",
        "ambulance kab tak pahunchegi", "send ambulance", "ambulance arrival time",
    ],
    "faq": [
        "what are the opd timings", "opd kitne baje khulta hai", "consultation fees",
        "how much is the fee", "what documents to bring", "visiting hours",
        "where is the hospital", "is parking available", "do you accept insurance",
        "hospital address", "timings", "emergency helpline number",
    ],
    "human": [
        "talk to a person", "connect me to staff", "i need human help",
        "customer care", "speak to receptionist", "agent please",
    ],
    "bye": ["bye", "thanks", "thank you", "goodbye", "ok thanks", "dhanyavad"],
}

_texts, _labels = [], []
for _intent, _examples in TRAIN.items():
    for _e in _examples:
        _texts.append(_e)
        _labels.append(_intent)

classifier = make_pipeline(
    TfidfVectorizer(ngram_range=(1, 2), lowercase=True),
    LogisticRegression(max_iter=1000, C=10),
)
classifier.fit(_texts, _labels)

CONFIDENCE_THRESHOLD = 0.30
EMERGENCY_WORDS = [
    "chest pain", "can't breathe", "cannot breathe", "breathing problem",
    "heart attack", "unconscious", "severe bleeding", "accident", "stroke",
    "seizure", "poison", "suicide",
]

MENU = ["Book token", "Check queue", "Cancel token", "Ambulance ETA", "OPD timings", "Talk to staff"]
BUTTON_INTENTS = {
    "book token": "book_token",
    "check queue": "check_queue",
    "cancel token": "cancel_token",
    "ambulance eta": "ambulance",
    "opd timings": "faq",
    "talk to staff": "human",
}


class ChatRequest(BaseModel):
    session_id: str
    message: str


class ChatResponse(BaseModel):
    reply: str
    buttons: list[str] = []
    intent: Optional[str] = None


def reply(text, buttons=None, intent=None):
    return ChatResponse(reply=text, buttons=buttons or [], intent=intent)


def minutes_text(m):
    return format_duration(m)


def find_department(text):
    for dept, words in DEPT_KEYWORDS.items():
        if dept.lower() in text or any(w in text for w in words):
            return dept
    return None


def find_doctor(text, dept):
    doctors = DOCTORS[dept]
    num = re.search(r"\b(\d{1,2})\b", text)
    if num and 1 <= int(num.group(1)) <= len(doctors):
        return doctors[int(num.group(1)) - 1]
    for d in doctors:
        if d["name"].lower().replace("dr. ", "") in text:
            return d
    return None


def find_number(text):
    m = re.search(r"\b(\d{1,5})\b", text)
    return int(m.group(1)) if m else None


def parse_visit_type(text):
    if "follow" in text or "revisit" in text or "repeat" in text or "old" in text:
        return "Follow-up"
    if "new" in text or "first" in text:
        return "New"
    return None


def parse_traffic(text):
    if any(w in text for w in ("low", "light", "clear")) or text.strip() == "1":
        return 1.0
    if any(w in text for w in ("medium", "moderate", "mid")) or text.strip() == "2":
        return 2.0
    if any(w in text for w in ("high", "heavy", "jam")) or text.strip() == "3":
        return 3.0
    return None


def parse_emergency_level(text):
    for level in ("Minor", "Major", "Critical"):
        if level.lower() in text:
            return level
    return None


def answer_faq(text):
    match = difflib.get_close_matches(text, FAQS.keys(), n=1, cutoff=0.35)
    if match:
        return FAQS[match[0]]
    words = set(text.split())
    best, score = None, 0
    for q in FAQS:
        overlap = len(words & set(q.split()))
        if overlap > score:
            best, score = q, overlap
    return FAQS[best] if best and score >= 1 else None

def tokens_ahead(doctor_id, token_no=None):
    """Active tokens of one doctor. If token_no is given, only those booked before it."""
    return [
        t for n, t in TOKENS.items()
        if t["status"] == "active"
        and t["doctor"]["id"] == doctor_id
        and (token_no is None or n < token_no)
    ]


def build_queue_input(dept, doctor, visit_type, complexity, urgent, ahead):
    """Turn the hospital's current state into the QueueInput your model expects."""
    now = datetime.now()
    status = DOCTOR_STATUS.get(doctor["id"])
    return QueueInput(
        Specialty=dept,
        Hour=now.hour,
        Day_Of_Week=now.weekday(),  # Monday=0 ... Sunday=6 (check this matches training)
        Doctor_Avg_Consult_Min=doctor["avg_consult_min"],
        Issue_Complexity=complexity,
        Visit_Type=visit_type,
        Is_Urgent=urgent,
        Patients_Waiting=len(ahead),
        Waiting_Short=sum(1 for t in ahead if t["complexity"] == "Short"),
        Waiting_Standard=sum(1 for t in ahead if t["complexity"] == "Standard"),
        Waiting_Long=sum(1 for t in ahead if t["complexity"] == "Long"),
        Waiting_New=sum(1 for t in ahead if t["visit_type"] == "New"),
        Waiting_Urgent=sum(t["urgent"] for t in ahead),
        Doctor_Busy=1 if status else 0,
        Current_Issue_Complexity=status["complexity"] if status else "None",
        Current_Consult_Elapsed_Min=status["elapsed_min"] if status else 0.0,
        Queue_Expected_Work_Min=sum(COMPLEXITY_MIN[t["complexity"]] for t in ahead),
    )


def estimate_wait(qin: QueueInput):
    """Model prediction, with a simple fallback if the model is unavailable."""
    try:
        return run_queue_model(qin)
    except HTTPException:
        return round(qin.Patients_Waiting * qin.Doctor_Avg_Consult_Min, 2)


def estimate_eta(distance_km, traffic_level, emergency_level):
    """Ambulance ETA from the model, with a simple fallback."""
    try:
        data = AmbulanceInput(
            Hour=datetime.now().hour,
            Traffic_Level=traffic_level,
            Distance_to_Incident=distance_km,
            Emergency_Level=emergency_level,
        )
        return run_ambulance_model(data)
    except HTTPException:
        base = distance_km / 40.0 * 60.0
        return round(base * (1 + 0.25 * (traffic_level - 1)), 2)


def token_status(token_no):
    t = TOKENS.get(token_no)
    if not t or t["status"] != "active":
        return None
    ahead = tokens_ahead(t["doctor"]["id"], token_no)
    qin = build_queue_input(t["dept"], t["doctor"], t["visit_type"], t["complexity"], t["urgent"], ahead)
    return t, len(ahead), estimate_wait(qin)


def begin_booking(sid, dept):
    doctors = DOCTORS[dept]
    SESSIONS[sid] = {"flow": "book", "step": "doctor", "dept": dept}
    lines = "\n".join(f"{i}. {d['name']}" for i, d in enumerate(doctors, 1))
    return reply(
        f"Doctors in {dept}:\n{lines}\nPlease choose a doctor (number or name).",
        [d["name"] for d in doctors], "book_token")


def flow_book(sid, state, text):
    step = state["step"]

    if step == "dept":
        dept = find_department(text)
        if not dept:
            return reply("Sorry, I couldn't find that department. Please choose one:",
                         list(DOCTORS), "book_token")
        return begin_booking(sid, dept)

    if step == "doctor":
        doctor = find_doctor(text, state["dept"])
        if not doctor:
            return reply("Please pick a doctor from the list.",
                         [d["name"] for d in DOCTORS[state["dept"]]], "book_token")
        state.update(step="visit", doctor=doctor)
        return reply("Is this a New visit or a Follow-up visit?", ["New", "Follow-up"], "book_token")

    if step == "visit":
        visit = parse_visit_type(text)
        if not visit:
            return reply("Please choose New or Follow-up.", ["New", "Follow-up"], "book_token")
        state.update(step="confirm", visit_type=visit)
        doctor = state["doctor"]
        qin = build_queue_input(state["dept"], doctor, visit, "Standard", 0, tokens_ahead(doctor["id"]))
        wait = estimate_wait(qin)
        return reply(
            f"Book a token with {doctor['name']} ({state['dept']}), {visit} visit? "
            f"Estimated wait if you book now: about {minutes_text(wait)}.",
            ["Yes", "No"], "book_token")

    if step == "confirm":
        if text in ("yes", "y", "ok", "haan", "confirm", "yes please"):
            doctor = state["doctor"]
            ahead = tokens_ahead(doctor["id"])
            qin = build_queue_input(state["dept"], doctor, state["visit_type"], "Standard", 0, ahead)
            wait = estimate_wait(qin)

            token_no = NEXT_TOKEN[0]
            NEXT_TOKEN[0] += 1
            TOKENS[token_no] = {
                "doctor": doctor, "dept": state["dept"], "status": "active",
                "visit_type": state["visit_type"], "complexity": "Standard", "urgent": 0,
            }
            SESSIONS.pop(sid, None)
            return reply(
                f"Token booked! Your token number is {token_no} with {doctor['name']}. "
                f"Patients ahead: {len(ahead)}. Estimated wait: about {minutes_text(wait)}.",
                MENU, "book_token")
        SESSIONS.pop(sid, None)
        return reply("Okay, booking cancelled. How else can I help?", MENU)


def flow_queue(sid, state, text):
    n = find_number(text)
    result = token_status(n) if n else None
    if not result:
        return reply("I couldn't find an active token with that number. Please enter it again, or type 'menu'.")
    t, ahead, wait = result
    SESSIONS.pop(sid, None)
    return reply(
        f"Token {n} ({t['doctor']['name']}): {ahead} patient(s) ahead of you. "
        f"Estimated wait: about {minutes_text(wait)}.",
        MENU, "check_queue")


def flow_cancel(sid, state, text):
    n = find_number(text)
    if not n or n not in TOKENS or TOKENS[n]["status"] != "active":
        return reply("I couldn't find an active token with that number. Please enter it again, or type 'menu'.")
    TOKENS[n]["status"] = "cancelled"
    SESSIONS.pop(sid, None)
    return reply(f"Token {n} has been cancelled.", MENU, "cancel_token")


def flow_ambulance(sid, state, text):
    step = state["step"]

    if step == "distance":
        m = re.search(r"(\d+(?:\.\d+)?)", text)
        if not m or not (0 < float(m.group(1)) <= 200):
            return reply("Please tell me the distance to the patient's location in km (for example 6.5).",
                         intent="ambulance")
        state.update(step="traffic", distance=float(m.group(1)))
        return reply("How is the traffic on the route?", ["Low", "Medium", "High"], "ambulance")

    if step == "traffic":
        level = parse_traffic(text)
        if level is None:
            return reply("Please choose Low, Medium or High.", ["Low", "Medium", "High"], "ambulance")
        state.update(step="level", traffic=level)
        return reply("What is the emergency level?", ["Minor", "Major", "Critical"], "ambulance")

    if step == "level":
        level = parse_emergency_level(text)
        if not level:
            return reply("Please choose Minor, Major or Critical.", ["Minor", "Major", "Critical"], "ambulance")
        eta = estimate_eta(state["distance"], state["traffic"], level)
        SESSIONS.pop(sid, None)
        return reply(
            f"Estimated ambulance arrival time: about {minutes_text(eta)}. "
            "This is only an estimate. To actually request an ambulance, call 102 / 108 now.",
            ["Talk to staff"] + MENU[:2], "ambulance")


FLOWS = {"book": flow_book, "queue": flow_queue, "cancel": flow_cancel, "ambulance": flow_ambulance}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    text = req.message.strip().lower()
    sid = req.session_id


    if any(w in text for w in EMERGENCY_WORDS):
        SESSIONS.pop(sid, None)
        return reply(
            "This sounds like an emergency. Please call 102 / 108 immediately or go to the "
            "Emergency department now. I cannot provide medical advice.",
            ["Ambulance ETA", "Talk to staff"], "emergency")

    state = SESSIONS.get(sid)
    if state and text in ("menu", "stop", "exit", "start over", "back"):
        SESSIONS.pop(sid, None)
        return reply("Okay. What would you like to do?", MENU)


    if state:
        return FLOWS[state["flow"]](sid, state, text)

  
    if text in BUTTON_INTENTS:
        intent, conf = BUTTON_INTENTS[text], 1.0
    else:
        intent = classifier.predict([text])[0]
        conf = float(classifier.predict_proba([text]).max())


    if conf < CONFIDENCE_THRESHOLD:
        faq = answer_faq(text)
        if faq:
            return reply(faq, MENU, "faq")
        return reply("Sorry, I didn't understand that. Here is what I can help with:", MENU, "fallback")
    if intent == "greeting":
        return reply("Hello! Welcome to our hospital helpdesk. How can I help you?", MENU, intent)

    if intent == "book_token":
        dept = find_department(text)
        if dept:
            return begin_booking(sid, dept)
        SESSIONS[sid] = {"flow": "book", "step": "dept"}
        return reply("Sure! Which department do you want to visit?", list(DOCTORS), intent)

    if intent == "check_queue":
        n = find_number(text)
        result = token_status(n) if n else None
        if result:
            t, ahead, wait = result
            return reply(
                f"Token {n} ({t['doctor']['name']}): {ahead} patient(s) ahead of you. "
                f"Estimated wait: about {minutes_text(wait)}.",
                MENU, intent)
        SESSIONS[sid] = {"flow": "queue", "step": "token"}
        return reply("Please enter your token number.", [], intent)

    if intent == "cancel_token":
        SESSIONS[sid] = {"flow": "cancel", "step": "token"}
        return reply("Please enter the token number you want to cancel.", [], intent)

    if intent == "ambulance":
        if any(w in text for w in ("number", "phone", "contact", "call")):
            return reply(FAQS["ambulance number"], MENU, "faq")
        SESSIONS[sid] = {"flow": "ambulance", "step": "distance"}
        return reply(
            "If this is an emergency, please call 102 / 108 right now. "
            "To estimate arrival time: how far is the patient from the hospital (in km)?",
            [], intent)

    if intent == "faq":
        faq = answer_faq(text)
        if faq:
            return reply(faq, MENU, intent)
        return reply("I'm not sure about that. You can ask about timings, fees, documents, "
                     "parking, visiting hours or insurance.", MENU, intent)

    if intent == "human":
        return reply("I'm connecting you to our helpdesk staff. You can also call the reception at 011-0000-0000.",
                     [], intent)

    if intent == "bye":
        return reply("You're welcome! Take care.", [], intent)

    return reply("How can I help you?", MENU, "fallback")


@app.get("/tokens")
def list_tokens():
    return TOKENS