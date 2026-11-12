"""Dialogue manager: turns a message into a reply by calling the hospital backend."""

import asyncio
import re
import time
from dataclasses import dataclass, field

from .backend_client import BackendClient, BackendError
from .faq import Faq
from .gemini_client import GeminiClient, GeminiError
from .ml_client import MLClient, MLError, ist_now, map_specialty
from .nlu import (
    detect_intent, is_no, is_yes, match_by_symptom, match_departments,
    match_doctors, normalize, pick_number,
)
from .policy import (
    REFUSAL_MEDICAL, SYSTEM_PROMPT, asks_for_medical_advice, privacy_refusal, redact, reply_is_unsafe,
)
from .sessions import Session, SessionStore, token_fingerprint
from .stats import Stats

EMERGENCY_TEXT = (
    "This sounds like it could be an emergency. Please call 112 (or 108 for an ambulance) "
    "right now, or go to the nearest emergency room. I can't help with emergencies from here. "
    "If you are having thoughts of harming yourself, you can also call Tele-MANAS at 14416."
)
DISCLAIMER = "I can't diagnose conditions; a doctor will assess you."
MAX_LIST = 8


@dataclass
class Reply:
    text: str
    intent: str
    suggestions: list[str] = field(default_factory=list)
    source: str = "rules"  # rules | gemini | fallback
    private: bool = False  # true while collecting personal details: never stored in Gemini history


# ------------------------------------------------------------- formatting
def _dept_name(doc: dict) -> str:
    dept = doc.get("department")
    return dept.get("name", "") if isinstance(dept, dict) else ""


def _doc_label(doc: dict) -> str:
    dept = _dept_name(doc)
    spec = doc.get("specialization", "")
    extra = ", ".join(x for x in (spec, dept) if x)
    return f"{doc.get('name', 'Doctor')} ({extra})" if extra else doc.get("name", "Doctor")


def _doc_line(doc: dict) -> str:
    bits = [_doc_label(doc)]
    if doc.get("consultationFee") is not None:
        bits.append(f"fee ₹{doc['consultationFee']}")
    if doc.get("experienceYears"):
        bits.append(f"{doc['experienceYears']} yrs experience")
    bits.append("accepting patients" if doc.get("isAvailable", True) else "not accepting new patients today")
    return " · ".join(bits)


def _numbered(docs: list[dict]) -> str:
    return "\n".join(f"{i}. {_doc_line(d)}" for i, d in enumerate(docs, 1))


def _token_doctor_name(token: dict) -> str:
    doc = token.get("doctor")
    if isinstance(doc, dict):
        return doc.get("name", "the doctor")
    return "the doctor"


def _minutes_text(minutes: float) -> str:
    if minutes < 1:
        return "under a minute"
    return f"about {round(minutes)} min"


def _wait_text(data: dict, ml_minutes: float | None = None) -> str:
    """Wait line for a token. Prefers the prediction API's estimate; falls back to the backend's own."""
    people = data.get("peopleAhead")
    parts = []
    if people is not None:
        parts.append(f"people ahead of you: {people}")
    if ml_minutes is not None:
        parts.append(f"estimated wait: {_minutes_text(ml_minutes)} (predicted from today's queue)")
    else:
        wait = data.get("estimatedWaitMinutes")
        if wait is not None:
            parts.append(f"estimated wait: {_minutes_text(float(wait))}")
    if not parts:
        return "A live wait estimate isn't available right now."
    return "; ".join(parts).capitalize() + ". (Estimates change as the queue moves; they aren't a guaranteed time.)"


def _token_summary(data: dict, ml_minutes: float | None = None, now_serving: int | None = None) -> str:
    tok = data.get("token", {})
    status = tok.get("status", "")
    head = f"Token #{tok.get('tokenNumber', '?')} with {_token_doctor_name(tok)} ({tok.get('queueDate', 'today')}) is {status}."
    if status == "called":
        return head + " It's your turn: please go to the consultation room now."
    if status == "waiting":
        serving = f" Now serving token #{now_serving}." if now_serving is not None else ""
        return head + "\n" + _wait_text(data, ml_minutes) + serving
    return head


# ---- ambulance message parsing ------------------------------------------------
_KM = re.compile(r"(\d+(?:\.\d+)?)\s*(?:km|kms|kilometers|kilometres|kilometer|kilometre|k m)\b")
_BARE_NUM = re.compile(r"^\s*(\d+(?:\.\d+)?)\s*$")


def _parse_distance(norm: str, bare_ok: bool = False) -> float | None:
    m = _KM.search(norm) or (_BARE_NUM.match(norm) if bare_ok else None)
    return float(m.group(1)) if m else None


def _ambulance_conditions(norm: str) -> dict:
    traffic = 3 if re.search(r"\b(heavy|jam|jammed|rush|congest\w*|busy traffic)\b", norm) else \
        1 if re.search(r"\b(light traffic|no traffic|empty roads?|low traffic)\b", norm) else 2
    weather = 2 if re.search(r"\b(storm|thunder\w*|cyclone|lightning)\b", norm) else \
        1 if re.search(r"\b(rain|raining|rainy|drizzle|showers?)\b", norm) else 0
    region = "Rural" if re.search(r"\b(rural|village)\b", norm) else "Suburban" if "suburb" in norm else "Urban"
    road = "Highway" if "highway" in norm else "Unpaved Road" if re.search(r"\b(unpaved|dirt|kachha)\b", norm) else "Local Road"
    level = "Critical" if "critical" in norm else "Major" if "major" in norm else "Minor"
    return {"traffic_level": traffic, "weather_severity": weather, "region": region, "road": road, "emergency_level": level}


_TOKEN_NO = re.compile(r"\btoken\s*(?:number|no|num)?\s*(\d{1,6})\b")
_ETA_WORDS = re.compile(r"\b(eta|how long|how much time|estimate|estimated|minutes|take|takes|time)\b")
_BOOK_AMB = re.compile(r"\b(book|request|need|send|arrange|want|get|call|require|order)\b")
_STATUS_AMB = re.compile(r"\b(status|track|assigned|my ambulance|my request|my ambulance request)\b")
_COORDS = re.compile(r"(-?\d{1,3}(?:\.\d+)?)\s*[, ]\s*(-?\d{1,3}(?:\.\d+)?)")
_PHONE = re.compile(r"\+?[1-9]\d{9,14}")
_SKIP = {"skip", "dont know", "do not know", "not sure", "no idea", "na", "n a", "unknown", "later"}
AMB_NOTE = ("This sends a request to hospital staff, who then assign a vehicle. It does NOT call emergency "
            "services: if someone's life is at risk, call 108 or 112 right now.")


def _clean_text(raw: str, limit: int = 300) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[\x00-\x1f\x7f]", " ", raw)).strip()[:limit]


def _parse_coords(raw: str) -> tuple[float, float] | None:
    m = _COORDS.search(raw)
    if not m:
        return None
    lat, lng = float(m.group(1)), float(m.group(2))
    return (lat, lng) if -90 <= lat <= 90 and -180 <= lng <= 180 else None


def _find_key(data, key: str):
    """First value stored under `key` anywhere in a nested JSON structure (the ETA response shape isn't fixed)."""
    if isinstance(data, dict):
        if key in data:
            return data[key]
        for v in data.values():
            found = _find_key(v, key)
            if found is not None:
                return found
    elif isinstance(data, list):
        for v in data:
            found = _find_key(v, key)
            if found is not None:
                return found
    return None


def _vehicle(req: dict) -> str | None:
    amb = req.get("ambulance")
    if isinstance(amb, dict):
        for k in ("vehicleNumber", "vehicleNo", "registrationNumber", "number", "plateNumber"):
            if amb.get(k):
                return str(amb[k])
    return None


class ChatEngine:
    def __init__(
        self,
        backend: BackendClient,
        sessions: SessionStore,
        ml: MLClient | None = None,
        gemini: GeminiClient | None = None,
        gemini_max_calls: int = 20,
        faq: Faq | None = None,
        stats: Stats | None = None,
    ):
        self.faq = faq
        self.stats = stats or Stats()
        self._summary_off_until = 0.0
        self.backend = backend
        self.sessions = sessions
        self.ml = ml
        self.gemini = gemini
        self.gemini_max_calls = gemini_max_calls

    # ------------------------------------------------- prediction API
    async def _ml_wait(self, data: dict) -> float | None:
        """Ask the prediction API how long a waiting token will wait. None means 'use the backend's estimate'."""
        if self.ml is None:
            return None
        tok = data.get("token", {})
        people = data.get("peopleAhead")
        if tok.get("status") != "waiting" or people is None:
            return None
        pred = data.get("prediction") or {}
        if pred.get("source") == "ml" and isinstance(data.get("estimatedWaitMinutes"), (int, float)):
            self.stats.event("ml_queue_from_backend")  # the backend already used the model, with richer live inputs
            return float(data["estimatedWaitMinutes"])
        doc_ref = tok.get("doctor")
        doc_id = doc_ref.get("_id") if isinstance(doc_ref, dict) else doc_ref
        try:
            doctors = await self.backend.doctors()
        except BackendError:
            doctors = []
        directory = next((d for d in doctors if d.get("_id") == doc_id), None)
        dept = ((directory or {}).get("department") or {}).get("name")
        if not dept and isinstance(doc_ref, dict):
            dept = (doc_ref.get("department") or {}).get("name")
        specialty = map_specialty(dept, (directory or {}).get("specialization"),
                                  doc_ref.get("specialization") if isinstance(doc_ref, dict) else None)
        if not specialty:
            return None  # the model only knows 10 specialties; other departments keep the backend estimate
        avg = (directory or {}).get("averageConsultationMinutes") or data.get("averageConsultationMinutes") or 10
        try:
            minutes = await self.ml.predict_queue(specialty, int(people), float(avg))
            self.stats.event("ml_queue_direct")
            return minutes
        except MLError:
            self.stats.event("ml_queue_fallback")
            return None

    # ------------------------------------------------------------ entry
    async def handle(
        self,
        session_id: str | None,
        text: str,
        token: str | None,
        mode: str = "auto",
        location: tuple[float, float] | None = None,
    ) -> tuple[Session, Reply]:
        sess = self.sessions.get(session_id)
        fingerprint = token_fingerprint(token)
        if sess.pending and sess.token_hash != fingerprint:
            sess.pending = None  # never let another login confirm someone else's action
        sess.token_hash = fingerprint
        if location:
            sess.location = location

        collecting = bool(sess.pending and str(sess.pending.get("type", "")).startswith("amb_"))
        try:
            reply = await self._dispatch(sess, normalize(text), text, token, mode)
        except BackendError as exc:
            sess.pending = None
            reply = self._error_reply(exc)
        reply.text = redact(reply.text)
        self.stats.message(reply.intent, reply.source)
        if not (collecting or reply.private):
            # Personal details (address, phone) typed during an ambulance request are never kept for Gemini.
            sess.history = (sess.history + [("user", text[:500]), ("model", reply.text[:800])])[-8:]
        return sess, reply

    async def _dispatch(self, sess: Session, norm: str, raw: str, token: str | None, mode: str = "auto") -> Reply:
        intent = detect_intent(norm)
        # Emergencies always win, even in the middle of another flow.
        if intent == "emergency":
            sess.pending = None
            return Reply(EMERGENCY_TEXT, "emergency")

        if sess.pending:
            pending, sess.pending = sess.pending, None
            reply = await self._handle_pending(sess, pending, norm, token, raw)
            if reply:
                return reply
            # not an answer to the pending question: treat as a fresh request

        refusal = privacy_refusal(norm)
        if refusal:
            self.stats.event("privacy_refusals")
            return Reply(refusal, "privacy_refusal", ["My token status", "Show departments"])

        faq = self.faq.match(norm) if self.faq else None
        if faq:
            self.stats.faq[faq.id] += 1
            return Reply(faq.answer, "faq", list(faq.suggestions) or self._menu())

        handler = {
            "token_lookup": self._token_lookup,
            "queue_info": self._queue_info,
            "ambulance": self._ambulance,
            "cancel": self._start_cancel,
            "book": self._start_booking,
            "status": self._status,
            "doctor_info": self._doctor_info,
            "list_departments": self._list_departments,
            "list_doctors": self._list_doctors,
        }.get(intent)
        if handler:
            return await handler(sess, norm, token)

        if intent == "greeting":
            return Reply("Hello! I'm the hospital queue assistant. I can show departments and doctors, "
                         "get you a queue token, and check or cancel your token.", "greeting", self._menu())
        if intent == "thanks":
            return Reply("You're welcome! Anything else I can help with?", "thanks", self._menu())
        if intent == "bye":
            return Reply("Take care! Wishing you good health.", "bye")
        if intent == "help":
            return Reply(self._help_text(), "help", self._menu())

        # Asking for medicines / doses / diagnosis is refused by code, before any model is involved.
        if asks_for_medical_advice(norm):
            return await self._medical_refusal(sess, norm)

        # No explicit intent: maybe they just named a department / doctor / symptom.
        reply = await self._guess_from_entities(sess, norm)
        if reply.intent == "unknown" and mode != "rules":
            gem = await self._ask_gemini(sess, raw)
            if gem:
                return gem
        return reply

    # ------------------------------------------------------- pending flow
    async def _handle_pending(self, sess: Session, pending: dict, norm: str, token: str | None, raw: str = "") -> Reply | None:
        kind = pending["type"]

        if kind.startswith("amb_"):
            return await self._handle_amb_pending(sess, pending, norm, token, raw)

        if kind in ("confirm_book", "confirm_cancel"):
            if is_yes(norm):
                return await (self._do_book(token, pending["doctor"]) if kind == "confirm_book"
                              else self._do_cancel(token, pending["token_id"]))
            if is_no(norm):
                return Reply("Okay, I've dropped that. Anything else?", "declined", self._menu())
            return None

        if kind == "choose_doctor":
            if is_no(norm):
                return Reply("No problem. Anything else I can do?", "declined", self._menu())
            cands = pending["doctors"]
            n = pick_number(norm)
            chosen = cands[n - 1] if n and 1 <= n <= len(cands) else None
            if not chosen:
                m = match_doctors(norm, cands)
                chosen = m[0] if len(m) == 1 else None
            return self._confirm_booking(sess, chosen) if chosen else None

        if kind == "ask_target":
            if is_no(norm):
                return Reply("No problem. Anything else I can do?", "declined", self._menu())
            return await self._book_target(sess, norm)

        if kind == "ask_lookup_doctor":
            if is_no(norm):
                return Reply("No problem. Anything else I can do?", "declined", self._menu())
            cands = pending["doctors"]
            n = pick_number(norm)
            chosen = cands[n - 1] if n and 1 <= n <= len(cands) else None
            if not chosen:
                m = match_doctors(norm, cands or await self.backend.doctors())
                chosen = m[0] if len(m) == 1 else None
            return await self._token_lookup_do(chosen, pending["number"]) if chosen else None

        if kind == "ask_queue_target":
            if is_no(norm):
                return Reply("No problem. Anything else I can do?", "declined", self._menu())
            return await self._queue_info_for(norm)  # None (no doctor/department named) = treat as a new request

        if kind == "ask_distance":
            distance = _parse_distance(norm, bare_ok=True)
            if distance is None:
                return None
            return await self._ambulance_eta(distance, f"{pending.get('text', '')} {norm}")

        if kind == "choose_cancel":
            if is_no(norm):
                return Reply("Okay, nothing was cancelled.", "declined", self._menu())
            n = pick_number(norm)
            items = pending["tokens"]
            if n and 1 <= n <= len(items):
                return self._confirm_cancel(sess, items[n - 1])
            return None
        return None

    # ----------------------------------------------------------- booking
    async def _start_booking(self, sess: Session, norm: str, token: str | None) -> Reply:
        if not token:
            return self._login_needed("join a queue")
        reply = await self._book_target(sess, norm)
        if reply:
            return reply
        depts = await self.backend.departments()
        names = [d["name"] for d in depts[:6]]
        sess.pending = {"type": "ask_target"}
        return Reply("Sure. Which department or doctor would you like to see today?", "book", names)

    async def _book_target(self, sess: Session, norm: str) -> Reply | None:
        doctors = await self.backend.doctors()
        depts = await self.backend.departments()

        named = match_doctors(norm, doctors)
        if len(named) == 1:
            return self._confirm_booking(sess, named[0])
        if len(named) > 1:
            return self._offer_choice(sess, named, "A few doctors match. Which one did you mean?")

        dept_hits = match_departments(norm, depts)
        via_symptom = False
        if not dept_hits:
            dept_hits = match_by_symptom(norm, depts)
            via_symptom = bool(dept_hits)
        if not dept_hits:
            return None

        ids = {d["_id"] for d in dept_hits}
        avail = [d for d in doctors if isinstance(d.get("department"), dict)
                 and d["department"].get("_id") in ids and d.get("isAvailable", True)]
        names = " / ".join(d["name"] for d in dept_hits)
        lead = f"{names} may be the right fit. {DISCLAIMER}\n" if via_symptom else ""
        if not avail:
            return Reply(lead + f"There are no doctors accepting new patients in {names} right now.",
                         "book", self._menu())
        if len(avail) == 1:
            return self._confirm_booking(sess, avail[0], prefix=lead)
        return self._offer_choice(sess, avail, lead + f"Doctors accepting patients in {names}:")

    def _offer_choice(self, sess: Session, docs: list[dict], intro: str) -> Reply:
        shown = docs[:MAX_LIST]
        sess.pending = {"type": "choose_doctor", "doctors": shown}
        return Reply(f"{intro}\n{_numbered(shown)}\nReply with a number or a doctor's name.",
                     "book", [str(i) for i in range(1, len(shown) + 1)][:5])

    def _confirm_booking(self, sess: Session, doc: dict, prefix: str = "") -> Reply:
        if not doc.get("isAvailable", True):
            return Reply(f"{doc.get('name')} isn't accepting new patients today. Would you like another doctor?",
                         "book", self._menu())
        sess.pending = {"type": "confirm_book", "doctor": {"_id": doc["_id"], "name": doc["name"], "label": _doc_label(doc)}}
        fee = f" The consultation fee is ₹{doc['consultationFee']} (informational; nothing is paid here)." \
            if doc.get("consultationFee") else ""
        return Reply(f"{prefix}Join today's queue with {_doc_label(doc)}?{fee}\nReply yes to confirm or no to cancel.",
                     "book_confirm", ["Yes", "No"])

    async def _do_book(self, token: str | None, doctor: dict) -> Reply:
        if not token:
            return self._login_needed("join a queue")
        data = await self.backend.book(token, doctor["_id"])
        tok = data.get("token", {})
        ml_minutes = await self._ml_wait(data)
        text = (f"You're in! Token #{tok.get('tokenNumber', '?')} with {doctor['label']} "
                f"for {tok.get('queueDate', 'today')}.\n{_wait_text(data, ml_minutes)}")
        return Reply(text, "booked", ["My token status", "Cancel my token"])

    # ------------------------------------------------------------ status
    async def _status(self, sess: Session, norm: str, token: str | None) -> Reply:
        if not re.search(r"\b(my|me|mine|i|ive|im)\b", norm):
            general = await self._queue_info_for(norm)  # e.g. "wait time for Dr Meera" is about the doctor's queue
            if general:
                return general
        if not token:
            return self._login_needed("check your token")
        tokens = await self.backend.my_tokens(token)
        active = [t for t in tokens if t.get("status") in ("waiting", "called")]
        if not active:
            done = len(tokens)
            extra = f" ({done} other token(s) today are completed, skipped or cancelled)" if done else ""
            return Reply(f"You have no active token today{extra}. Want to join a queue?", "status", ["Book a token"])

        async def one(t: dict) -> str:
            try:
                data = await self.backend.token_status(token, t["_id"])
            except BackendError:
                return f"Token #{t.get('tokenNumber', '?')} with {_token_doctor_name(t)} is {t.get('status')}."
            doc_ref = data.get("token", {}).get("doctor")
            doc_id = doc_ref.get("_id") if isinstance(doc_ref, dict) else doc_ref
            summary = await self._summary(doc_id) if doc_id and data.get("token", {}).get("status") == "waiting" else None
            serving = (summary or {}).get("nowServingToken")
            return _token_summary(data, await self._ml_wait(data), serving if isinstance(serving, int) else None)

        lines = await asyncio.gather(*(one(t) for t in active[:5]))
        return Reply("\n\n".join(lines), "status", ["Cancel my token"] if any(t["status"] == "waiting" for t in active) else [])

    # ------------------------------------------------------------ cancel
    async def _start_cancel(self, sess: Session, norm: str, token: str | None) -> Reply:
        if not token:
            return self._login_needed("cancel a token")
        tokens = await self.backend.my_tokens(token)
        waiting = [{"id": t["_id"], "label": f"Token #{t.get('tokenNumber', '?')} with {_token_doctor_name(t)}"}
                   for t in tokens if t.get("status") == "waiting"]
        if not waiting:
            return Reply("You have no waiting token to cancel. (A token that has already been called can't be cancelled here.)",
                         "cancel", self._menu())
        if len(waiting) == 1:
            return self._confirm_cancel(sess, waiting[0])
        sess.pending = {"type": "choose_cancel", "tokens": waiting}
        listing = "\n".join(f"{i}. {w['label']}" for i, w in enumerate(waiting, 1))
        return Reply(f"Which token would you like to cancel?\n{listing}", "cancel", [str(i) for i in range(1, len(waiting) + 1)][:5])

    def _confirm_cancel(self, sess: Session, item: dict) -> Reply:
        sess.pending = {"type": "confirm_cancel", "token_id": item["id"], "label": item["label"]}
        return Reply(f"Cancel {item['label']}? You'd lose your place in line. Reply yes to confirm or no to keep it.",
                     "cancel_confirm", ["Yes", "No"])

    async def _do_cancel(self, token: str | None, token_id: str) -> Reply:
        if not token:
            return self._login_needed("cancel a token")
        await self.backend.cancel(token, token_id)
        return Reply("Your token has been cancelled. You can join the queue again any time today.", "cancelled", ["Book a token"])

    # --------------------------------------------------------- directory
    async def _list_departments(self, sess: Session, norm: str, token: str | None) -> Reply:
        depts = await self.backend.departments()
        if not depts:
            return Reply("I couldn't find any departments right now.", "list_departments")
        body = "\n".join(f"- {d['name']}" for d in depts)
        return Reply(f"We have these departments:\n{body}\nTell me one to see its doctors.", "list_departments",
                     [d["name"] for d in depts[:4]])

    async def _list_doctors(self, sess: Session, norm: str, token: str | None) -> Reply:
        doctors = await self.backend.doctors()
        depts = await self.backend.departments()

        named = match_doctors(norm, doctors)
        if named:
            return Reply(_numbered(named[:MAX_LIST]), "list_doctors", ["Book a token"])

        hits = match_departments(norm, depts) or match_by_symptom(norm, depts)
        if hits:
            ids = {d["_id"] for d in hits}
            docs = [d for d in doctors if isinstance(d.get("department"), dict) and d["department"].get("_id") in ids]
            if not docs:
                return Reply(f"No doctors are listed under {' / '.join(h['name'] for h in hits)} yet.", "list_doctors", self._menu())
            docs.sort(key=lambda d: not d.get("isAvailable", True))
            more = f"\n...and {len(docs) - MAX_LIST} more." if len(docs) > MAX_LIST else ""
            return Reply(f"Doctors in {' / '.join(h['name'] for h in hits)}:\n{_numbered(docs[:MAX_LIST])}{more}",
                         "list_doctors", ["Book a token"])

        avail = [d for d in doctors if d.get("isAvailable", True)]
        if not avail:
            return Reply("No doctors are accepting new patients right now.", "list_doctors", self._menu())
        more = f"\n...and {len(avail) - MAX_LIST} more. Name a department to narrow it down." if len(avail) > MAX_LIST else ""
        return Reply(f"Doctors accepting patients today:\n{_numbered(avail[:MAX_LIST])}{more}", "list_doctors",
                     [d["name"] for d in depts[:3]])

    async def _doctor_info(self, sess: Session, norm: str, token: str | None) -> Reply:
        doctors = await self.backend.doctors()
        named = match_doctors(norm, doctors)
        if named:
            return Reply(_numbered(named[:MAX_LIST]), "doctor_info", ["Book a token"])
        return await self._list_doctors(sess, norm, token)

    async def _guess_from_entities(self, sess: Session, norm: str) -> Reply:
        doctors = await self.backend.doctors()
        depts = await self.backend.departments()
        if match_doctors(norm, doctors) or match_departments(norm, depts) or match_by_symptom(norm, depts):
            reply = await self._list_doctors(sess, norm, None)
            if match_by_symptom(norm, depts) and not match_departments(norm, depts):
                reply.text = f"{DISCLAIMER}\n{reply.text}"
            return reply
        return Reply("Sorry, I didn't quite get that. I can help with departments, doctors, joining a queue, "
                     "checking or cancelling your token, and ambulance requests.", "unknown", self._menu(), source="fallback")

    # ------------------------------------- public token lookup (no login)
    async def _token_lookup(self, sess: Session, norm: str, token: str | None) -> Reply:
        """'How many people are before token 12 for Dr X?' answered from the token number alone."""
        m = _TOKEN_NO.search(norm)
        if not m:
            return await self._queue_info(sess, norm, token)
        number = int(m.group(1))
        if number < 1:
            return Reply("Token numbers start at 1.", "token_lookup", self._menu())
        doctors = await self.backend.doctors()
        depts = await self.backend.departments()
        named = match_doctors(norm, doctors)
        if len(named) == 1:
            return await self._token_lookup_do(named[0], number)
        cands = named
        if not cands:
            hits = match_departments(norm, depts) or match_by_symptom(norm, depts)
            ids = {h["_id"] for h in hits}
            cands = [d for d in doctors if isinstance(d.get("department"), dict) and d["department"].get("_id") in ids]
        cands = cands[:MAX_LIST]
        sess.pending = {"type": "ask_lookup_doctor", "number": number, "doctors": cands}
        if cands:
            return Reply(f"Token numbers are per doctor. Which doctor is token #{number} for?\n{_numbered(cands)}\n"
                         "Reply with a number or a doctor's name.", "token_lookup", [str(i) for i in range(1, len(cands) + 1)][:5])
        return Reply(f"Token numbers are per doctor. Which doctor is token #{number} for?", "token_lookup",
                     [d["name"] for d in depts[:4]])

    async def _token_lookup_do(self, doc: dict, number: int) -> Reply:
        name = doc.get("name", "the doctor")
        try:
            data = await self.backend.token_lookup(doc["_id"], number)
        except BackendError as exc:
            if exc.code == "TOKEN_NOT_FOUND":
                return Reply(f"There's no token #{number} with {name} today.", "token_lookup", self._menu())
            if exc.status == 404 and exc.code == "NOT_FOUND":
                self.stats.event("token_lookup_endpoint_missing")
                return Reply("Looking up a token by number isn't switched on yet. Personal token details aren't "
                             "available through this lookup.", "token_lookup", ["Show departments"])
            raise
        self.stats.event("token_lookup")
        state = data.get("state")
        if state == "called":
            text = f"Token #{number} with {name} is being called right now."
        elif state == "waiting":
            people = data.get("peopleAhead")
            text = f"Token #{number} with {name} is waiting"
            if isinstance(people, int):
                text += f": {people} {'person' if people == 1 else 'people'} ahead"
                minutes, source = None, ""
                specialty = map_specialty(_dept_name(doc), doc.get("specialization"))
                if self.ml and specialty:
                    try:
                        avg = float(data.get("averageConsultationMinutes") or doc.get("averageConsultationMinutes") or 10)
                        minutes = await self.ml.predict_queue(specialty, people, avg)
                        source = " (predicted)"
                        self.stats.event("ml_queue_direct")
                    except MLError:
                        self.stats.event("ml_queue_fallback")
                if minutes is None and isinstance(data.get("estimatedWaitMinutes"), (int, float)):
                    minutes = float(data["estimatedWaitMinutes"])
                if minutes is not None:
                    text += f", estimated wait {_minutes_text(minutes)}{source}"
            text += "."
        else:
            text = f"Token #{number} with {name} is no longer in today's queue."
        return Reply(text + "\nI can only show token numbers, never who holds a token.", "token_lookup",
                 ["Book a token", "Show departments"])

    # --------------------------------------------- live queue inquiries
    async def _summary(self, doctor_id: str) -> dict | None:
        """Aggregate queue numbers for a doctor, or None if the backend doesn't offer them (yet) or failed.
        When the route is missing we stop asking for 5 minutes instead of failing on every message."""
        if time.monotonic() < self._summary_off_until:
            return None
        try:
            return await self.backend.queue_summary(doctor_id)
        except BackendError as exc:
            if exc.status == 404 and exc.code == "NOT_FOUND":
                self._summary_off_until = time.monotonic() + 300
                self.stats.event("queue_summary_endpoint_missing")
            else:
                self.stats.event("queue_summary_error")
            return None

    async def _queue_info(self, sess: Session, norm: str, token: str | None) -> Reply:
        reply = await self._queue_info_for(norm)
        if reply:
            return reply
        depts = await self.backend.departments()
        sess.pending = {"type": "ask_queue_target"}
        return Reply("Which doctor or department would you like the live queue for? "
                     "(For your own token, say 'my token status'.)", "queue_info", [d["name"] for d in depts[:4]])

    async def _queue_info_for(self, norm: str) -> Reply | None:
        doctors = await self.backend.doctors()
        depts = await self.backend.departments()
        targets = match_doctors(norm, doctors)
        label = None
        if not targets:
            hits = match_departments(norm, depts) or match_by_symptom(norm, depts)
            if hits:
                ids = {h["_id"] for h in hits}
                targets = [d for d in doctors if isinstance(d.get("department"), dict) and d["department"].get("_id") in ids]
                label = " / ".join(h["name"] for h in hits)
                if not targets:
                    return Reply(f"No doctors are listed under {label} yet.", "queue_info", self._menu())
        if not targets:
            return None
        targets = sorted(targets, key=lambda d: not d.get("isAvailable", True))
        shown = targets[:5]
        summaries = await asyncio.gather(*(self._summary(d["_id"]) for d in shown))
        lines = await asyncio.gather(*(self._queue_line(d, sm) for d, sm in zip(shown, summaries)))
        head = f"Live queue today for {label}:" if label else "Live queue today:"
        more = f"\n...and {len(targets) - len(shown)} more. Name a doctor for details." if len(targets) > len(shown) else ""
        who = "\nI can only show token numbers, never who is in the queue." if re.search(r"\bwho\b", norm) else ""
        return Reply(head + "\n" + "\n".join(lines) + more + who + "\nThese numbers change as the queue moves.",
                     "queue_info", ["Book a token", "My token status"])

    async def _queue_line(self, doc: dict, sm: dict | None) -> str:
        name = f"{doc.get('name', 'Doctor')} ({_dept_name(doc)})" if _dept_name(doc) else doc.get("name", "Doctor")
        avg = doc.get("averageConsultationMinutes") or (sm or {}).get("averageConsultationMinutes")
        available = doc.get("isAvailable", True) and (sm or {}).get("doctor", {}).get("isAvailable", True)
        if sm is None:
            tail = f"; consultations take about {avg} min on average" if avg else ""
            avail = "accepting patients" if available else "not accepting new patients today"
            return f"- {name}: {avail}. Live queue numbers aren't available right now{tail}."
        waiting = sm.get("waitingCount")
        parts = [f"{waiting} waiting" if isinstance(waiting, int) else "waiting count unavailable"]
        serving = sm.get("nowServingToken")
        parts.append(f"now serving token #{serving}" if isinstance(serving, int) else "no consultation in progress")
        if not available:
            parts.append("not accepting new patients today")
        elif isinstance(waiting, int):
            minutes, source = None, ""
            specialty = map_specialty(_dept_name(doc), doc.get("specialization"))
            if self.ml and specialty:
                try:
                    minutes = await self.ml.predict_queue(specialty, waiting, float(avg or 10))
                    source = " (predicted)"
                    self.stats.event("ml_queue_direct")
                except MLError:
                    self.stats.event("ml_queue_fallback")
            if minutes is None and isinstance(sm.get("estimatedWaitIfJoinedNowMinutes"), (int, float)):
                minutes = float(sm["estimatedWaitIfJoinedNowMinutes"])
            if minutes is not None:
                parts.append(f"about {round(minutes)} min if you join now{source}")
        return f"- {name}: " + " · ".join(parts)

    # ------------------------------------------------- ambulance requests
    async def _amb_book_start(self, sess: Session, token: str | None) -> Reply:
        if not token:
            return self._login_needed("request an ambulance")
        active = [r for r in await self.backend.my_ambulance_requests(token) if r.get("status") in ("pending", "assigned")]
        if active:
            return Reply(f"You already have an active ambulance request (status: {active[0].get('status')}). "
                         "Say 'ambulance status' to follow it.", "ambulance_active", ["Ambulance status"])
        sess.pending = {"type": "amb_address", "amb": {}}
        return Reply(f"{AMB_NOTE}\n\nWhat is the pickup address? (Say 'stop' any time to drop this.)",
                     "ambulance_ask_address", private=True)

    async def _handle_amb_pending(self, sess: Session, pending: dict, norm: str, token: str | None, raw: str) -> Reply | None:
        kind, amb = pending["type"], pending.get("amb", {})
        if is_no(norm) or norm in {"stop", "exit", "quit"}:
            return Reply("Okay, I've dropped that request. Nothing was sent.", "declined", self._menu())

        if kind == "amb_confirm_cancel":
            return await self._amb_cancel_do(token, pending["id"]) if is_yes(norm) else None

        if kind == "amb_address":
            addr = _clean_text(raw)
            if len(addr) < 5:
                sess.pending = pending
                return Reply("Please give a fuller pickup address (at least 5 characters).", "ambulance_ask_address", private=True)
            amb["address"] = addr
            sess.pending = {"type": "amb_phone", "amb": amb}
            return Reply("Thanks. What phone number can the hospital call you on? (10-15 digits, e.g. +919876543210)",
                         "ambulance_ask_phone", private=True)

        if kind == "amb_phone":
            digits = re.sub(r"[\s\-().]", "", raw)
            if not _PHONE.fullmatch(digits):
                sess.pending = pending
                return Reply("That doesn't look like a valid phone number. Please send 10-15 digits, optionally starting with +.",
                             "ambulance_ask_phone", private=True)
            amb["phone"] = digits
            return self._amb_after_phone(sess, amb)

        if kind == "amb_location":
            coords = _parse_coords(raw) or sess.location
            if not coords:
                sess.pending = pending
                return Reply("I couldn't read a location. Tap the location button in the app, or type coordinates like 28.6692, 77.4538.",
                             "ambulance_ask_location", private=True)
            amb["lat"], amb["lng"] = coords
            return self._amb_ask_distance(sess, amb)

        if kind == "amb_distance":
            if norm in _SKIP:
                return await self._amb_confirm(sess, amb, None, None)
            distance = _parse_distance(norm, bare_ok=True)
            if distance is None:
                sess.pending = pending
                return Reply("Please give the distance in km, or say 'skip'.", "ambulance_ask_distance", ["skip"], private=True)
            if distance > 50:
                sess.pending = pending
                return Reply("That's beyond the 50 km range I can estimate. Your request can still be sent: say 'skip' to continue "
                             "without an estimate.", "ambulance_ask_distance", ["skip"], private=True)
            minutes, how, _ = await self._predict_eta(max(distance, 1.0), norm)
            return await self._amb_confirm(sess, amb, minutes, how)

        if kind == "amb_confirm":
            if is_yes(norm):
                return await self._amb_book_do(token, amb, pending.get("eta"))
            return None
        return None

    def _amb_after_phone(self, sess: Session, amb: dict) -> Reply:
        if sess.location:
            amb["lat"], amb["lng"] = sess.location
            return self._amb_ask_distance(sess, amb)
        sess.pending = {"type": "amb_location", "amb": amb}
        return Reply("Now your location. Tap the location button in the app to share it, or type coordinates like 28.6692, 77.4538.",
                     "ambulance_ask_location", private=True)

    def _amb_ask_distance(self, sess: Session, amb: dict) -> Reply:
        sess.pending = {"type": "amb_distance", "amb": amb}
        return Reply("Optional: roughly how far is the hospital from you, in km? I'll estimate the ambulance travel time. "
                     "(Add 'heavy traffic' or 'raining' if that applies, or say 'skip'.)",
                     "ambulance_ask_distance", ["skip", "5 km", "10 km"], private=True)

    async def _amb_confirm(self, sess: Session, amb: dict, minutes: float | None, how: str | None) -> Reply:
        eta_line = f"\nEstimated travel time once assigned: {_minutes_text(minutes)} ({how})." if minutes is not None else ""
        sess.pending = {"type": "amb_confirm", "amb": amb, "eta": (minutes, how) if minutes is not None else None}
        tail = amb["phone"][-4:]
        return Reply(f"Please confirm your ambulance request:\n- Pickup: {amb['address']}\n- Phone: ending {tail}\n"
                     f"- Location: {amb['lat']:.4f}, {amb['lng']:.4f}{eta_line}\n\n{AMB_NOTE}\nSend this request? (yes / no)",
                     "ambulance_confirm", ["Yes", "No"], private=True)

    async def _amb_book_do(self, token: str | None, amb: dict, eta) -> Reply:
        if not token:
            return self._login_needed("request an ambulance")
        data = await self.backend.create_ambulance_request(token, amb["address"], amb["lat"], amb["lng"], amb["phone"])
        status = (data.get("request") or {}).get("status", "pending")
        eta_line = f" Estimated travel time once a vehicle is assigned: {_minutes_text(eta[0])}." if eta else ""
        return Reply(f"Your ambulance request has been sent (status: {status}). Hospital staff will assign a vehicle.{eta_line}\n"
                     "Say 'ambulance status' to follow it. If it's urgent, call 108 or 112 now.", "ambulance_booked",
                     ["Ambulance status"], private=True)

    async def _amb_status(self, sess: Session, token: str | None) -> Reply:
        if not token:
            return self._login_needed("check your ambulance request")
        reqs = await self.backend.my_ambulance_requests(token)
        active = [r for r in reqs if r.get("status") in ("pending", "assigned")]
        if not active:
            last = f" Your last request was {reqs[0].get('status')}." if reqs else ""
            return Reply(f"You have no active ambulance request.{last}", "ambulance_status", ["Book an ambulance"])
        lines = []
        for r in active[:3]:
            if r["status"] == "pending":
                lines.append("Your ambulance request is pending: staff haven't assigned a vehicle yet.")
                continue
            veh = _vehicle(r)
            line = f"An ambulance{f' ({veh})' if veh else ''} has been assigned to you."
            try:
                eta = await self.backend.ambulance_eta(token, r["_id"])
            except BackendError:
                eta = {}
            minutes = _find_key(eta, "etaMinutes")
            if isinstance(minutes, (int, float)):
                line += f" Estimated arrival: {_minutes_text(float(minutes))}."
            elif _find_key(eta, "reason") == "ambulance_location_stale_or_missing":
                line += " A live arrival estimate isn't available right now (the ambulance's location hasn't been updated recently)."
            else:
                line += " A live arrival estimate isn't available right now."
            lines.append(line)
        return Reply("\n".join(lines) + "\nFor urgent help, call 108 or 112.", "ambulance_status", ["Cancel ambulance"])

    async def _amb_cancel_start(self, sess: Session, token: str | None) -> Reply:
        if not token:
            return self._login_needed("cancel an ambulance request")
        reqs = await self.backend.my_ambulance_requests(token)
        pending = [r for r in reqs if r.get("status") == "pending"]
        if not pending:
            if any(r.get("status") == "assigned" for r in reqs):
                return Reply("A vehicle has already been assigned, so only hospital staff can cancel it. Please call the hospital.",
                             "ambulance_cancel")
            return Reply("You have no pending ambulance request to cancel.", "ambulance_cancel", self._menu())
        sess.pending = {"type": "amb_confirm_cancel", "id": pending[0]["_id"]}
        return Reply("Cancel your pending ambulance request? (yes / no)", "ambulance_cancel_confirm", ["Yes", "No"])

    async def _amb_cancel_do(self, token: str | None, request_id: str) -> Reply:
        if not token:
            return self._login_needed("cancel an ambulance request")
        await self.backend.cancel_ambulance_request(token, request_id)
        return Reply("Your ambulance request has been cancelled.", "ambulance_cancelled", self._menu())

    # ---------------------------------------------------------- gemini guide
    async def _medical_refusal(self, sess: Session, norm: str) -> Reply:
        text = REFUSAL_MEDICAL
        try:
            hits = match_by_symptom(norm, await self.backend.departments())
        except BackendError:
            hits = []
        if hits:
            text += f"\nFor what you describe, {' / '.join(h['name'] for h in hits[:2])} may be the right department."
        self.stats.event("medical_refusals")
        return Reply(text, "medical_refusal", ["Available doctors", "Book a token"])

    async def _ask_gemini(self, sess: Session, raw: str) -> Reply | None:
        if not self.gemini or sess.gemini_calls >= self.gemini_max_calls:
            return None
        sess.gemini_calls += 1
        self.stats.event("gemini_calls")
        prompt = SYSTEM_PROMPT
        try:
            names = [d["name"] for d in await self.backend.departments()][:30]
            if names:
                prompt += "\nDepartments currently listed in this hospital: " + ", ".join(names) + ".\n"
        except BackendError:
            pass
        try:
            text = await self.gemini.generate(prompt, sess.history[-6:], raw[:500])
        except GeminiError as exc:
            self.stats.event(f"gemini_failed_{exc.reason}")
            return None
        if reply_is_unsafe(text):
            self.stats.event("gemini_unsafe_reply_blocked")
            return Reply(REFUSAL_MEDICAL, "medical_refusal", ["Available doctors", "Book a token"], source="fallback")
        return Reply(text[:1500], "gemini", self._menu(), source="gemini")

    # ------------------------------------------------------------- misc
    async def _predict_eta(self, distance: float, norm: str) -> tuple[float, str, dict]:
        """Ambulance travel time from the prediction API, or distance / 40 km/h if it is unavailable."""
        cond = _ambulance_conditions(norm)
        try:
            if self.ml is None:
                raise MLError("not_configured")
            minutes = await self.ml.predict_ambulance(distance, now=ist_now(), **cond)
            self.stats.event("ml_ambulance_direct")
            return minutes, "predicted from distance, traffic, weather and time of day", cond
        except MLError:
            self.stats.event("ml_ambulance_fallback")
            return distance / 40.0 * 60.0, "rough figure at 40 km/h: the prediction service is unavailable", cond

    async def _ambulance(self, sess: Session, norm: str, token: str | None) -> Reply:
        if re.search(r"\bcancel\b", norm):
            return await self._amb_cancel_start(sess, token)
        if _STATUS_AMB.search(norm):
            return await self._amb_status(sess, token)
        distance = _parse_distance(norm)
        if not _ETA_WORDS.search(norm) and _BOOK_AMB.search(norm):
            return await self._amb_book_start(sess, token)
        if distance is None and not _ETA_WORDS.search(norm):
            return Reply("I can request an ambulance for you, check a request, or estimate travel time. What would you like?",
                         "ambulance", ["Book an ambulance", "Ambulance status", "Ambulance ETA"])
        if distance is None:
            sess.pending = {"type": "ask_distance", "text": norm}
            return Reply("I can estimate an ambulance's travel time. How far is the pickup point, in km? "
                         "(You can add conditions like 'heavy traffic', 'raining' or 'highway'.)\n"
                         "If someone's life is at risk, call 108 or 112 now; don't wait for an estimate.",
                         "ambulance", ["5 km", "10 km", "20 km"])
        return await self._ambulance_eta(distance, norm)

    async def _ambulance_eta(self, distance: float, norm: str) -> Reply:
        sos = "\nIf this is an emergency, call 108 or 112 right away."
        if distance > 50:
            return Reply("That's beyond the 50 km range my estimates cover. Please call 108 or 112 to dispatch an ambulance." , "ambulance")
        distance = max(distance, 1.0)
        minutes, how, cond = await self._predict_eta(distance, norm)
        notes = []
        if cond["traffic_level"] == 2 and "traffic" not in norm:
            notes.append("moderate traffic")
        if cond["weather_severity"] == 0 and not re.search(r"rain|storm", norm):
            notes.append("clear weather")
        assumed = f" Assumed: {', '.join(notes)}." if notes else ""
        return Reply(f"For {distance:g} km, an ambulance would take {_minutes_text(minutes)} ({how}).{assumed}{sos}",
                     "ambulance_eta", ["Show departments", "My token status"])

    def _login_needed(self, action: str) -> Reply:
        return Reply(f"I can't {action} from this request because a patient session wasn't provided. "
                     "I can still help with public information, including departments, doctors, and queue estimates.",
                     "login_required", ["Show departments"])

    def _error_reply(self, exc: BackendError) -> Reply:
        code, status = exc.code, exc.status
        self.stats.event(f"backend_error_{code}")
        if status == 401:
            return Reply("The patient session is unavailable or has expired. I can't complete this personal action "
                         "from the current request.", "error")
        if status == 403:
            return Reply("This is only available from a patient account.", "error")
        known = {
            "ALREADY_IN_QUEUE": "You already have an active token with this doctor today. Say 'my token status' to see it.",
            "DOCTOR_UNAVAILABLE": "That doctor just stopped accepting new patients. Want to pick another doctor?",
            "DOCTOR_NOT_FOUND": "I couldn't find that doctor any more. Let's pick again.",
            "TOKEN_NOT_FOUND": "I couldn't find that token. Say 'my token status' to see your current tokens.",
            "TOKEN_NOT_CANCELLABLE": "That token can no longer be cancelled; it may already have been called or finished.",
            "QUEUE_CONFLICT": "Two requests collided. Please check 'my token status' before trying again, so you don't book twice.",
            "QUEUE_DAY_CHANGED": "The day changed while booking. Please try again.",
            "ACTIVE_REQUEST_EXISTS": "You already have an active ambulance request. Say 'ambulance status' to follow it.",
            "REQUEST_NOT_FOUND": "I couldn't find that ambulance request.",
            "REQUEST_CONFLICT": "That ambulance request can't be changed any more; it may already be assigned or closed.",
            "VALIDATION_ERROR": "Some of those details weren't accepted by the system. Please check them and try again.",
            "RATE_LIMITED": "Too many requests in a short time. Please wait a few minutes and try again.",
        }
        if code in known:
            return Reply(known[code], "error", self._menu())
        if code == "BACKEND_UNREACHABLE" or status >= 500:
            return Reply("The hospital system isn't responding right now. Please try again in a moment.", "error")
        return Reply("Something went wrong with that request. Please try again.", "error")

    @staticmethod
    def _menu() -> list[str]:
        return ["Show departments", "Available doctors", "Book a token", "My token status"]

    @staticmethod
    def _help_text() -> str:
        return ("I can:\n- list departments and doctors (try 'doctors in cardiology')\n"
                "- get you a queue token for today ('book Dr Sharma')\n"
                "- show your token, people ahead and estimated wait ('my token status')\n"
                "- cancel a waiting token ('cancel my token')\n"
                "- request an ambulance ('book an ambulance'), check it ('ambulance status') or cancel it\n"
                "- estimate ambulance travel time ('ambulance eta 8 km, heavy traffic')\n"
                "- show live queue numbers for a doctor or department ('how many people are waiting for Dr Sharma?')\n"
                "- answer common questions (login, tokens, why a wait changes) and other questions about this system\n"
                "I only show your own data and general queue numbers, never other patients' details.\n"
                "Note: these are same-day queue tokens, not time-slot appointments.")
