import hashlib
import time
import uuid
from dataclasses import dataclass, field


def token_fingerprint(token: str | None) -> str | None:
    """One-way hash so a session can tell whether the same user is still talking.
    The raw token is never stored."""
    return hashlib.sha256(token.encode()).hexdigest() if token else None


@dataclass
class Session:
    id: str
    pending: dict | None = None  # multi-turn state: confirmations, choices
    token_hash: str | None = None
    location: tuple[float, float] | None = None  # (lat, lng) shared by the client, in memory only
    history: list = field(default_factory=list)  # [(role, text)] for the Gemini assistant
    gemini_calls: int = 0
    touched: float = field(default_factory=time.monotonic)


class SessionStore:
    def __init__(self, ttl_seconds: int = 1800, max_sessions: int = 5000):
        self._ttl = ttl_seconds
        self._max = max_sessions
        self._data: dict[str, Session] = {}

    def _purge(self) -> None:
        now = time.monotonic()
        for sid in [s for s, v in self._data.items() if now - v.touched > self._ttl]:
            del self._data[sid]
        while len(self._data) >= self._max:
            oldest = min(self._data.values(), key=lambda v: v.touched)
            del self._data[oldest.id]

    def get(self, session_id: str | None) -> Session:
        self._purge()
        sess = self._data.get(session_id) if session_id else None
        if sess is None:
            sess = Session(id=uuid.uuid4().hex)
            self._data[sess.id] = sess
        sess.touched = time.monotonic()
        return sess
