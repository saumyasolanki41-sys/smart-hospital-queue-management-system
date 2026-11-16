
import json
import re
from dataclasses import dataclass
from pathlib import Path

DEFAULT_FILE = Path(__file__).parent / "data" / "faq.json"


@dataclass(frozen=True)
class FaqEntry:
    id: str
    patterns: list[re.Pattern]
    answer: str
    suggestions: tuple[str, ...] = ()


class Faq:
    def __init__(self, entries: list[FaqEntry]):
        self.entries = entries

    @classmethod
    def load(cls, path: str | Path | None = None) -> "Faq":
        raw = json.loads(Path(path or DEFAULT_FILE).read_text(encoding="utf-8"))
        entries = []
        for item in raw:
            entries.append(FaqEntry(
                id=item["id"],
                patterns=[re.compile(p) for p in item["patterns"]],
                answer=item["answer"],
                suggestions=tuple(item.get("suggestions", [])),
            ))
        return cls(entries)

    def match(self, norm_text: str) -> FaqEntry | None:
        for entry in self.entries:
            if any(p.search(norm_text) for p in entry.patterns):
                return entry
        return None
