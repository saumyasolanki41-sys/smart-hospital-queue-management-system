import { ChevronLeft, ChevronRight } from "lucide-react";

function pageList(current, total) {
  const wanted = [1, total, current - 1, current, current + 1];
  const pages = [...new Set(wanted)].filter((p) => p >= 1 && p <= total).sort((a, b) => a - b);

  const items = [];
  pages.forEach((p, i) => {
    if (i > 0 && p - pages[i - 1] > 1) items.push(`gap-${p}`); // a string marks a "…"
    items.push(p);
  });
  return items;
}

export default function Pagination({ page, totalPages, onChange, label = "Pagination" }) {
  if (totalPages <= 1) return null;

  const button =
    "flex h-9 min-w-[2.25rem] items-center justify-center rounded-lg px-3 text-sm font-medium transition-colors";
  const plain = "border border-slate-200 bg-white text-slate-700 hover:bg-primary/5";

  return (
    <nav aria-label={label} className="flex flex-wrap items-center justify-center gap-1.5">
      <button
        type="button"
        onClick={() => onChange(page - 1)}
        disabled={page === 1}
        aria-label="Previous page"
        className={`${button} ${plain} disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-white`}
      >
        <ChevronLeft className="h-4 w-4" />
      </button>

      {pageList(page, totalPages).map((item) =>
        typeof item === "string" ? (
          <span key={item} aria-hidden="true" className="px-1 text-slate-400">
            …
          </span>
        ) : (
          <button
            key={item}
            type="button"
            onClick={() => onChange(item)}
            aria-label={`Page ${item}`}
            aria-current={item === page ? "page" : undefined}
            className={`${button} ${item === page ? "bg-primary/70 text-white shadow-sm" : plain}`}
          >
            {item}
          </button>
        )
      )}

      <button
        type="button"
        onClick={() => onChange(page + 1)}
        disabled={page === totalPages}
        aria-label="Next page"
        className={`${button} ${plain} disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-white`}
      >
        <ChevronRight className="h-4 w-4" />
      </button>
    </nav>
  );
}