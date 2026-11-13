"""Anonymous, in-memory usage counters so the team can see which inquiries are common and where
fallbacks happen. No message text, names, phone numbers or tokens are ever recorded."""

import time
from collections import Counter


class Stats:
    def __init__(self) -> None:
        self.started = time.time()
        self.messages = 0
        self.intents: Counter[str] = Counter()
        self.sources: Counter[str] = Counter()
        self.faq: Counter[str] = Counter()
        self.events: Counter[str] = Counter()  # ml_*, gemini_*, backend_error_*, privacy_refusals, ...

    def message(self, intent: str, source: str) -> None:
        self.messages += 1
        self.intents[intent] += 1
        self.sources[source] += 1

    def event(self, name: str) -> None:
        self.events[name] += 1

    def snapshot(self, top: int = 10) -> dict:
        return {
            "since": self.started,
            "uptime_seconds": int(time.time() - self.started),
            "messages": self.messages,
            "top_inquiries": [{"intent": k, "count": v} for k, v in self.intents.most_common(top)],
            "top_faq": [{"id": k, "count": v} for k, v in self.faq.most_common(top)],
            "by_source": dict(self.sources),
            "events": dict(self.events),
            "unanswered": self.intents.get("unknown", 0),
        }
