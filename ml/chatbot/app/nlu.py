"""Rule-based language understanding: intents plus fuzzy department/doctor matching.

No external model is needed, so replies are fast, free and predictable. Matching is
done against the live directory, so new departments/doctors work without code changes.
"""

import re
from difflib import get_close_matches

TITLES = {"dr", "doctor", "prof", "mr", "mrs", "ms"}
# Words that appear in doctor names in test data or in everyday chat; never match on these.
GENERIC = {
    "patient", "test", "doctor", "book", "token", "queue", "available", "please",
    "with", "today", "the", "and", "for", "see", "want", "need", "appointment",
}

YES = {"yes", "y", "yeah", "yep", "sure", "ok", "okay", "confirm", "confirmed", "go ahead", "book it", "do it", "please do"}
NO = {"no", "n", "nope", "nah", "stop", "never mind", "nevermind", "dont", "don t", "abort", "cancel"}

# symptom / body-part word -> department name stems (matched at the start of a word)
SYMPTOMS: dict[str, tuple[str, ...]] = {
    "heart": ("cardio",), "cardiac": ("cardio",), "chest": ("cardio", "pulmon"),
    "blood pressure": ("cardio",), "palpitation": ("cardio",),
    "skin": ("dermat",), "rash": ("dermat",), "acne": ("dermat",), "hair": ("dermat",), "itching": ("dermat",),
    "bone": ("ortho",), "fracture": ("ortho",), "joint": ("ortho",), "knee": ("ortho",), "back pain": ("ortho",),
    "eye": ("ophthal",), "vision": ("ophthal",),
    "child": ("pediat", "paediat"), "children": ("pediat", "paediat"), "baby": ("pediat", "paediat"), "kid": ("pediat", "paediat"),
    "ear": ("ent", "otolaryng", "ear"), "nose": ("ent", "otolaryng"), "throat": ("ent", "otolaryng"),
    "tooth": ("dent",), "teeth": ("dent",),
    "brain": ("neuro",), "migraine": ("neuro",), "headache": ("neuro",), "seizure": ("neuro",),
    "pregnant": ("gyn", "obstet"), "pregnancy": ("gyn", "obstet"), "period": ("gyn",),
    "stomach": ("gastro",), "digestion": ("gastro",), "acidity": ("gastro",),
    "kidney": ("nephro", "uro"), "urine": ("uro", "nephro"),
    "fever": ("general", "internal"), "cold": ("general", "internal"), "cough": ("general", "internal", "pulmon"),
    "diabetes": ("endocrin", "internal", "general"), "thyroid": ("endocrin",),
    "anxiety": ("psych",), "depression": ("psych",),
    "breathing": ("pulmon", "respirat"), "asthma": ("pulmon", "respirat"),
    "cancer": ("onco",),
}


def normalize(text: str) -> str:
    t = text.lower().replace("'", "").replace("’", "")
    t = re.sub(r"[^a-z0-9]+", " ", t)
    return re.sub(r"\s+", " ", t).strip()


def is_yes(norm: str) -> bool:
    return norm in YES


def is_no(norm: str) -> bool:
    return norm in NO


def pick_number(norm: str) -> int | None:
    m = re.fullmatch(r"(?:option |number |choice |no )?(\d{1,2})", norm)
    return int(m.group(1)) if m else None


# ---------------------------------------------------------------- intents
_RULES: list[tuple[str, str]] = [
    ("emergency", r"\b(emergency|heart attack|stroke|cant breathe|cannot breathe|unconscious|severe bleeding|bleeding heavily|overdose|poison|suicide|suicidal|kill myself|self harm)\b"),
    ("ambulance", r"\bambulance\b"),
    ("cancel", r"\b(cancel|withdraw|leave the queue|remove my token)\b"),
    ("status", r"\b(ahead of me|before me|in front of me|my turn|my position)\b"),
    ("token_lookup", r"^(?!.*\b(book|join|register|my|mine)\b).*\btoken\s*(?:number|no|num)?\s*\d{1,6}\b"),
        ("queue_info", r"^(?!.*\b(?:my|mine)\b).*\b(?:estimate(?:d)?(?: wait(?:ing)?)? time|wait(?:ing)? time)\b"),
    ("queue_info", r"\b(how many (people|patients)|queue (length|size|status)|crowd\w*|now serving|currently serving|current token|which token|"
                   r"who is being served|next token|how busy|is it busy|how long is the (queue|wait|line)|waiting (for|at|outside)|people waiting|patients waiting)\b"),
    ("book", r"\b(book|join|appointment|get a token|take a token|new token|register for|consult)\b"),
    ("status", r"\b(status|my token|my tokens|my turn|my queue|my booking|my bookings|where am i|my position|estimate(?:d)?(?: wait(?:ing)?)? time|wait(?:ing)? time|wait|waiting|how long|how many people|how many patients|eta|turn)\b"),
    ("doctor_info", r"\b(fee|fees|cost|price|charge|charges|experience)\b"),
    ("list_departments", r"\b(department|departments|specialities|specialties|speciality|specialty)\b"),
    ("list_doctors", r"\b(doctor|doctors|dr|physician|specialist|available)\b"),
    ("greeting", r"^(hi|hii|hello|hey|namaste|good morning|good afternoon|good evening)\b"),
    ("thanks", r"\b(thanks|thank you|thx|shukriya|dhanyavad)\b"),
    ("bye", r"^(bye|goodbye|see you|exit|quit)\b"),
    ("help", r"\b(help|what can you do|options|menu|how does this work)\b"),
]


def detect_intent(norm: str) -> str:
    for name, pattern in _RULES:
        if re.search(pattern, norm):
            return name
    return "unknown"


# --------------------------------------------------------------- matching
def _words(norm: str) -> list[str]:
    return norm.split()


def match_departments(norm: str, departments: list[dict]) -> list[dict]:
    """Departments mentioned by name (typos tolerated)."""
    hits = []
    for d in departments:
        name = normalize(d.get("name", ""))
        if name and re.search(rf"\b{re.escape(name)}\b", norm):
            hits.append(d)
    if hits:
        return hits

    words = [w for w in _words(norm) if len(w) >= 5 and w not in GENERIC]
    for d in departments:
        tokens = [t for t in normalize(d.get("name", "")).split() if len(t) >= 4 and t not in {"care", "department"}]
        for w in words:
            if any(token.startswith(w) for token in tokens) or get_close_matches(w, tokens, n=1, cutoff=0.84):
                hits.append(d)
                break
    return hits


def match_by_symptom(norm: str, departments: list[dict]) -> list[dict]:
    """Departments suggested by a symptom / body-part word. Not a diagnosis."""
    stems: list[str] = []
    for key, group in SYMPTOMS.items():
        if re.search(rf"\b{re.escape(key)}\b", norm):
            stems.extend(group)
    hits = []
    for d in departments:
        name = normalize(d.get("name", ""))
        if any(re.search(rf"\b{re.escape(s)}", name) for s in stems):
            hits.append(d)
    return hits


def _name_tokens(name: str) -> list[str]:
    return [t for t in normalize(name).split() if t not in TITLES and len(t) >= 3 and t not in GENERIC]


def match_doctors(norm: str, doctors: list[dict], max_ties: int = 6) -> list[dict]:
    """Doctors whose name appears in the text. Returns the best-scoring group
    (several only when the user was ambiguous, e.g. just a shared surname)."""
    words = _words(norm)
    scored: list[tuple[float, dict]] = []
    for doc in doctors:
        tokens = _name_tokens(doc.get("name", ""))
        if not tokens:
            continue
        found = sum(1 for t in tokens if t in words or get_close_matches(t, words, n=1, cutoff=0.86))
        if found:
            scored.append((found / len(tokens), doc))
    if not scored:
        return []
    best = max(s for s, _ in scored)
    top = [d for s, d in scored if s == best]
    return top if len(top) <= max_ties else []
