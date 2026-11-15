import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  Calendar,
  Filter,
  RefreshCw,
  Star,
  MessageSquarePlus,
  Clock,
  CheckCircle2,
  ChevronRight,
  Info,
} from "lucide-react";
import Navbar from "../components/layout/Navbar";
import StatusBadge from "../components/queue/StatusBadge";
import Pagination from "../components/common/Pagination";
import FeedbackModal from "../components/queue/FeedbackModal";
import { useAuth } from "../components/context/AuthContext";
import { getVisitHistory } from "../api/queue";

const STATUS_OPTIONS = [
  { value: "completed", label: "Completed" },
  { value: "all", label: "All statuses" },
  { value: "waiting", label: "Waiting" },
  { value: "called", label: "Called" },
  { value: "cancelled", label: "Cancelled" },
  { value: "skipped", label: "Skipped" },
];

const LIMIT = 20;

export default function VisitHistory() {
  const { token: accessToken, signOut } = useAuth();

  const [visits, setVisits] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState("completed");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [dateError, setDateError] = useState("");

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [updatedAt, setUpdatedAt] = useState(null);

  // Feedback modal
  const [activeFeedbackToken, setActiveFeedbackToken] = useState(null);

  const loadHistory = useCallback(async () => {
    // Check for inverted date range
    if (fromDate && toDate && fromDate > toDate) {
      setDateError("'From' date cannot be after 'To' date.");
      return;
    }
    setDateError("");
    setLoading(true);
    setError("");

    try {
      const res = await getVisitHistory(accessToken, {
        status: statusFilter,
        from: fromDate || undefined,
        to: toDate || undefined,
        page,
        limit: LIMIT,
      });

      setVisits(res.visits || []);
      setTotal(res.total || 0);
      setUpdatedAt(new Date());
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut();
        return;
      }
      setError(err.message || "Failed to load visit history.");
    } finally {
      setLoading(false);
    }
  }, [accessToken, statusFilter, fromDate, toDate, page, signOut]);

  useEffect(() => {
    loadHistory();
  }, [loadHistory]);

  function handleStatusChange(e) {
    setStatusFilter(e.target.value);
    setPage(1);
  }

  function handleFromChange(e) {
    setFromDate(e.target.value);
    setPage(1);
  }

  function handleToChange(e) {
    setToDate(e.target.value);
    setPage(1);
  }

  function clearDates() {
    setFromDate("");
    setToDate("");
    setDateError("");
    setPage(1);
  }

  function handleFeedbackSaved(tokenId, feedback) {
    setVisits((prev) =>
      prev.map((v) => (v._id === tokenId ? { ...v, feedback } : v))
    );
  }

  const totalPages = Math.max(1, Math.ceil(total / LIMIT));

  return (
    <div className="min-h-screen bg-transparent">
      <Navbar />

      <main className="mx-auto max-w-5xl px-6 pb-20 pt-6">
        <header className="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="mb-1 text-base font-semibold text-[#197092]">Patient Records</p>
            <h1 className="text-3xl font-bold text-slate-900">Visit History</h1>
            <p className="mt-1 text-sm text-slate-600">
              View your past consultations, queue tokens, and leave feedback.
            </p>
          </div>

          <button
            type="button"
            onClick={loadHistory}
            disabled={loading}
            className="inline-flex items-center gap-1.5 rounded-xl border border-slate-200/80 bg-white/90 px-3.5 py-2 text-sm font-medium text-slate-600 shadow-sm hover:text-[#197092] hover:bg-cyan-50/50 transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
            {updatedAt ? `Updated ${updatedAt.toLocaleTimeString()}` : "Refresh"}
          </button>
        </header>

        {/* Filter Bar */}
        <section
          aria-label="Filter history"
          className="mb-6 rounded-3xl bg-white/90 backdrop-blur-md p-5 shadow-xl shadow-cyan-950/5 border border-white/80"
        >
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div className="flex flex-wrap items-center gap-3">
              {/* Status Select */}
              <div className="flex items-center gap-2">
                <Filter className="h-4 w-4 text-[#197092]" />
                <label htmlFor="history-status" className="text-xs font-semibold text-slate-600">
                  Status:
                </label>
                <select
                  id="history-status"
                  value={statusFilter}
                  onChange={handleStatusChange}
                  className="rounded-xl border border-slate-200/80 bg-white px-3 py-1.5 text-sm font-medium text-slate-800 outline-none focus:border-[#197092] focus:ring-2 focus:ring-cyan-500/20"
                >
                  {STATUS_OPTIONS.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Date Filters */}
              <div className="flex flex-wrap items-center gap-2 border-l border-slate-200/80 pl-3">
                <Calendar className="h-4 w-4 text-[#197092]" />
                <div className="flex items-center gap-1.5 text-xs text-slate-600 font-semibold">
                  <span>From:</span>
                  <input
                    type="date"
                    value={fromDate}
                    onChange={handleFromChange}
                    className="rounded-xl border border-slate-200/80 bg-white px-2.5 py-1 text-xs text-slate-800 outline-none focus:border-[#197092]"
                  />
                </div>
                <div className="flex items-center gap-1.5 text-xs text-slate-600 font-semibold">
                  <span>To:</span>
                  <input
                    type="date"
                    value={toDate}
                    onChange={handleToChange}
                    className="rounded-xl border border-slate-200/80 bg-white px-2.5 py-1 text-xs text-slate-800 outline-none focus:border-[#197092]"
                  />
                </div>
                {(fromDate || toDate) && (
                  <button
                    type="button"
                    onClick={clearDates}
                    className="text-xs text-[#197092] font-semibold hover:underline ml-1"
                  >
                    Clear dates
                  </button>
                )}
              </div>
            </div>

            <div className="text-xs font-medium text-slate-500">
              Total visits: <span className="font-bold text-slate-900">{total}</span>
            </div>
          </div>

          {dateError && (
            <p role="alert" className="mt-3 text-xs font-medium text-red-600">
              {dateError}
            </p>
          )}
        </section>

        {error && (
          <div role="alert" className="mb-6 rounded-2xl bg-red-50 p-4 text-sm text-red-700 border border-red-200">
            {error}
          </div>
        )}

        {/* Visits List */}
        {loading && visits.length === 0 ? (
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-28 animate-pulse rounded-3xl bg-white/70 shadow-sm" />
            ))}
          </div>
        ) : visits.length === 0 ? (
          <div className="rounded-3xl bg-white/90 backdrop-blur-md p-12 text-center shadow-xl shadow-cyan-950/5 border border-white/80">
            <Calendar className="mx-auto h-12 w-12 text-slate-300 mb-3" />
            <h3 className="text-lg font-bold text-slate-800">No visits found</h3>
            <p className="mt-1 text-sm text-slate-500 max-w-sm mx-auto">
              {fromDate || toDate || statusFilter !== "completed"
                ? "Try adjusting your dates or status filter to see more records."
                : "You don't have any completed consultations recorded yet."}
            </p>
            {(fromDate || toDate || statusFilter !== "completed") && (
              <button
                type="button"
                onClick={() => {
                  setStatusFilter("completed");
                  clearDates();
                }}
                className="mt-4 rounded-xl bg-[#197092] px-4 py-2 text-xs font-semibold text-white shadow-sm hover:bg-[#145d7a] transition-colors"
              >
                Reset filters
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-4">
            {visits.map((visit) => {
              const docName = visit.doctor?.name ?? "Doctor no longer listed";
              const deptName = visit.doctor?.department?.name ?? "Department unavailable";
              const isCompleted = visit.status === "completed";
              const hasFeedback = Boolean(visit.feedback);

              return (
                <article
                  key={visit._id}
                  className="rounded-3xl bg-white/90 backdrop-blur-md p-5 shadow-md shadow-cyan-950/5 border border-white/80 hover:shadow-lg transition-all"
                >
                  <div className="flex flex-wrap items-center justify-between gap-4">
                    <div className="flex items-center gap-4 min-w-0">
                      <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-cyan-50 text-xl font-bold text-[#197092] border border-cyan-100 shadow-sm">
                        #{visit.tokenNumber}
                      </span>
                      <div className="min-w-0">
                        <div className="flex flex-wrap items-center gap-2">
                          <h2 className="truncate text-base font-bold text-slate-900">
                            {docName}
                          </h2>
                          <StatusBadge status={visit.status} />
                        </div>
                        <p className="text-xs text-slate-500 mt-0.5">
                          {deptName}
                          {visit.doctor?.specialization ? ` · ${visit.doctor.specialization}` : ""}
                        </p>
                        <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
                          <span>Queue date: {visit.queueDate}</span>
                          {visit.completedAt && (
                            <>
                              <span>•</span>
                              <span>
                                Completed at{" "}
                                {new Date(visit.completedAt).toLocaleTimeString("en-IN", {
                                  hour: "2-digit",
                                  minute: "2-digit",
                                })}
                              </span>
                            </>
                          )}
                        </p>
                      </div>
                    </div>

                    <div className="flex flex-wrap items-center gap-3">
                      {/* Feedback section */}
                      {hasFeedback ? (
                        <button
                          type="button"
                          onClick={() => setActiveFeedbackToken(visit)}
                          className="flex items-center gap-2 rounded-2xl bg-amber-50/80 border border-amber-200/80 px-3.5 py-2 text-xs font-medium text-amber-800 hover:bg-amber-100 transition-colors shadow-sm"
                        >
                          <div className="flex gap-0.5">
                            {[1, 2, 3, 4, 5].map((s) => (
                              <Star
                                key={s}
                                className={`h-3.5 w-3.5 ${
                                  s <= visit.feedback.rating
                                    ? "fill-amber-400 text-amber-400"
                                    : "text-slate-300"
                                }`}
                              />
                            ))}
                          </div>
                          <span>Feedback saved</span>
                        </button>
                      ) : isCompleted ? (
                        <button
                          type="button"
                          onClick={() => setActiveFeedbackToken(visit)}
                          className="flex items-center gap-1.5 rounded-2xl bg-[#197092] hover:bg-[#145d7a] px-4 py-2 text-xs font-semibold text-white shadow-sm transition-colors"
                        >
                          <MessageSquarePlus className="h-3.5 w-3.5" />
                          <span>Leave feedback</span>
                        </button>
                      ) : null}

                      <Link
                        to={`/queue/${visit._id}`}
                        className="inline-flex items-center gap-1 text-xs font-semibold text-[#197092] hover:underline px-2 py-1"
                      >
                        Details
                        <ChevronRight className="h-3.5 w-3.5" />
                      </Link>
                    </div>
                  </div>

                  {/* Feedback preview if comment exists */}
                  {hasFeedback && visit.feedback.comment && (
                    <div className="mt-3.5 border-t border-slate-100 pt-3 text-xs text-slate-600 bg-slate-50/60 rounded-xl p-2.5">
                      <span className="font-semibold text-slate-700">Your note: </span>
                      <span className="italic">"{visit.feedback.comment}"</span>
                    </div>
                  )}
                </article>
              );
            })}

            {totalPages > 1 && (
              <div className="mt-8 flex flex-col items-center gap-2">
                <Pagination
                  page={page}
                  totalPages={totalPages}
                  onChange={setPage}
                  label="Visit history pagination"
                />
                <p className="text-xs text-slate-500">
                  Showing {(page - 1) * LIMIT + 1}–{Math.min(page * LIMIT, total)} of {total} visits
                </p>
              </div>
            )}
          </div>
        )}

        {/* Feedback Modal */}
        {activeFeedbackToken && (
          <FeedbackModal
            token={activeFeedbackToken}
            isOpen={Boolean(activeFeedbackToken)}
            onClose={() => setActiveFeedbackToken(null)}
            onFeedbackSaved={handleFeedbackSaved}
            accessToken={accessToken}
          />
        )}
      </main>
    </div>
  );
}
