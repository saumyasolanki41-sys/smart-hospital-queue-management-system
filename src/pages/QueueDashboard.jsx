// src/pages/QueueDashboard.jsx
import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import {
  PhoneCall,
  Check,
  SkipForward,
  RefreshCw,
  Pause,
  Play,
  PauseCircle,
  X,
  AlertCircle,
  Clock,
} from "lucide-react";
import Navbar from "../components/layout/Navbar";
import AllDoctorsOverview from "../components/staff/AllDoctorsOverview";
import { useAuth } from "../components/context/AuthContext";
import { getDoctors } from "../api/hospital";
import {
  getDoctorQueue,
  callNext,
  completeToken,
  skipToken,
  pauseDoctorQueue,
  resumeDoctorQueue,
  getDashboardSummary,
} from "../api/staff";
import { getDoctorDashboard } from "../api/doctor";
import { timeAgo } from "../utils/time";

const REFRESH_MS = 10000;
const LIST_LIMIT = 50;

const ACTION_MESSAGES = {
  QUEUE_BUSY:
    "An active consultation is in progress. Please complete or skip the current consultation before pausing the queue or calling another patient.",
  QUEUE_PAUSED:
    "The queue is currently paused. Please resume the queue before calling the next patient.",
  QUEUE_EMPTY: "No patients are waiting right now.",
  TOKEN_NOT_CALLED: "That patient is no longer in the called state. The queue has been refreshed.",
  RATE_LIMITED: "Too many actions in a short time. Please wait a few minutes.",
  FORBIDDEN: "You don't have access to this doctor's queue.",
};

const fmtTime = (iso) =>
  iso ? new Date(iso).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }) : "";

function Skeleton() {
  return (
    <div className="grid gap-6 lg:grid-cols-5">
      <div className="h-72 animate-pulse rounded-3xl bg-white/70 lg:col-span-2" />
      <div className="h-72 animate-pulse rounded-3xl bg-white/70 lg:col-span-3" />
    </div>
  );
}

const TOKEN_TILES = [
  { key: "total", label: "Total tokens", style: "bg-slate-50 text-slate-900" },
  { key: "waiting", label: "Waiting", style: "bg-yellow-50 text-yellow-900" },
  { key: "called", label: "Being served", style: "bg-primary/5 text-primary/90" },
  { key: "completed", label: "Completed", style: "bg-green-50 text-green-900" },
  { key: "cancelled", label: "Cancelled", style: "bg-gray-100 text-gray-800" },
  { key: "skipped", label: "Skipped", style: "bg-orange-50 text-orange-900" },
];

function SummaryStrip({ summary }) {
  const { tokens, doctors, departments } = summary;
  return (
    <section
      aria-label="Today's summary"
      className="mb-6 rounded-3xl bg-white/90 backdrop-blur-md p-5 shadow-xl shadow-cyan-950/5 border border-white/70"
    >
      <div className="mb-3 flex flex-wrap items-baseline justify-between gap-2">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Hospital-wide today</h2>
        <p className="text-sm text-slate-600">
          {doctors.available} of {doctors.total} doctors accepting bookings · {departments}{" "}
          {departments === 1 ? "department" : "departments"}
        </p>
      </div>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        {TOKEN_TILES.map(({ key, label, style }) => (
          <div key={key} className={`rounded-2xl p-3 ${style}`}>
            <p className="text-2xl font-bold">{tokens[key]}</p>
            <p className="text-xs">{label}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function DoctorSummaryStrip({ summary }) {
  const { doctor: profile, tokens } = summary;
  const tiles = [
    { key: "total", label: "Total tokens" },
    { key: "waiting", label: "Waiting" },
    { key: "called", label: "Called today" },
    { key: "completed", label: "Completed" },
    { key: "cancelled", label: "Cancelled" },
    { key: "skipped", label: "Skipped" },
  ];

  return (
    <section aria-label="Today's doctor summary" className="mb-6 rounded-3xl bg-white/95 p-5 shadow-xl">
      <div className="mb-3 flex flex-wrap items-baseline justify-between gap-2">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">
          Today · {summary.date}
        </h2>
        <p className="text-sm text-slate-600">
          {profile.department?.name ?? "Department unavailable"}
          {profile.averageConsultationMinutes
            ? ` · About ${profile.averageConsultationMinutes} min per consultation`
            : ""}
        </p>
      </div>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        {tiles.map(({ key, label }) => (
          <div key={key} className="rounded-2xl bg-secondary/5 p-3 text-slate-900">
            <p className="text-2xl font-bold">{tokens[key] ?? 0}</p>
            <p className="text-xs">{label}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function PauseQueueModal({ isOpen, onClose, onConfirm, busy }) {
  const [reason, setReason] = useState("break");

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="relative w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-100 sm:p-7">
        <button
          type="button"
          onClick={onClose}
          className="absolute right-5 top-5 rounded-full p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors"
          aria-label="Close modal"
        >
          <X className="h-5 w-5" />
        </button>

        <div className="mb-5">
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-amber-100 text-amber-700 mb-3">
            <Pause className="h-6 w-6" />
          </div>
          <h2 className="text-xl font-bold text-slate-900">Pause Queue</h2>
          <p className="mt-1 text-sm text-slate-600">
            Temporarily halt calling next patients. Existing tokens and waiting order will be preserved.
          </p>
        </div>

        <div className="space-y-3 mb-6">
          <label className="text-xs font-semibold uppercase tracking-wider text-slate-500">
            Select Pause Reason
          </label>

          <label
            className={`flex items-start gap-3 rounded-2xl border p-4 cursor-pointer transition-all ${
              reason === "break"
                ? "border-amber-400 bg-amber-50/60 ring-2 ring-amber-400/20"
                : "border-slate-200 bg-white hover:bg-slate-50"
            }`}
          >
            <input
              type="radio"
              name="pause-reason"
              value="break"
              checked={reason === "break"}
              onChange={() => setReason("break")}
              className="mt-0.5 h-4 w-4 accent-amber-600"
            />
            <div>
              <p className="text-sm font-bold text-slate-900">Doctor's Break</p>
              <p className="text-xs text-slate-500 mt-0.5">
                Tea, lunch, or short rest break.
              </p>
            </div>
          </label>

          <label
            className={`flex items-start gap-3 rounded-2xl border p-4 cursor-pointer transition-all ${
              reason === "temporary_delay"
                ? "border-amber-400 bg-amber-50/60 ring-2 ring-amber-400/20"
                : "border-slate-200 bg-white hover:bg-slate-50"
            }`}
          >
            <input
              type="radio"
              name="pause-reason"
              value="temporary_delay"
              checked={reason === "temporary_delay"}
              onChange={() => setReason("temporary_delay")}
              className="mt-0.5 h-4 w-4 accent-amber-600"
            />
            <div>
              <p className="text-sm font-bold text-slate-900">Temporary Delay</p>
              <p className="text-xs text-slate-500 mt-0.5">
                Ward rounds, emergency case, or clinical meeting.
              </p>
            </div>
          </label>
        </div>

        <div className="rounded-xl bg-slate-50 p-3 text-xs text-slate-600 mb-6 border border-slate-200/60">
          <span className="font-semibold text-slate-700">Note:</span> If a patient is currently being consulted, complete or skip their visit first.
        </div>

        <div className="flex gap-3">
          <button
            type="button"
            onClick={onClose}
            disabled={busy}
            className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={busy}
            onClick={() => onConfirm(reason)}
            className="flex-1 rounded-xl bg-amber-600 hover:bg-amber-700 py-2.5 text-sm font-semibold text-white shadow-md shadow-amber-600/20 transition-colors disabled:opacity-60"
          >
            {busy ? "Pausing…" : "Confirm Pause"}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function QueueDashboard({ mode }) {
  const { token: accessToken, signOut } = useAuth();
  const [searchParams, setSearchParams] = useSearchParams();

  const [doctors, setDoctors] = useState([]);
  const [ownDoctorId, setOwnDoctorId] = useState(null);
  const [setupLoading, setSetupLoading] = useState(true);
  const [setupError, setSetupError] = useState("");

  // Queue
  const [queue, setQueue] = useState(null); // { tokens, currentToken, date, queueState }
  const [queueState, setQueueState] = useState(null); // { paused, reason, pausedAt }
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [updatedAt, setUpdatedAt] = useState(null);
  const [acting, setActing] = useState(false);
  const [confirmSkip, setConfirmSkip] = useState(false);
  const [summary, setSummary] = useState(null); // hospital-wide counts (staff mode only)
  const [doctorSummary, setDoctorSummary] = useState(null);

  // Pause Modal
  const [showPauseModal, setShowPauseModal] = useState(false);

  const selection = searchParams.get("doctor") || "all";
  const isAll = mode === "staff" && selection === "all";
  const doctorId = mode === "doctor" ? ownDoctorId : isAll ? null : selection;
  const doctor = doctors.find((d) => d._id === doctorId);

  useEffect(() => {
    let ignore = false;

    async function setup() {
      try {
        if (mode === "doctor") {
          const dashboard = await getDoctorDashboard(accessToken);
          if (ignore) return;
          setDoctorSummary(dashboard);
          setDoctors([dashboard.doctor]);
          setOwnDoctorId(dashboard.doctor._id);
          if (dashboard.queueState) setQueueState(dashboard.queueState);
          return;
        }

        const list = await getDoctors({ limit: LIST_LIMIT });
        if (ignore) return;
        setDoctors(list);
      } catch (err) {
        if (!ignore) {
          if (err.code === "UNAUTHORIZED") {
            signOut();
            return;
          }
          setSetupError(
            err.code === "DOCTOR_NOT_FOUND"
              ? "No doctor profile is linked to your account yet. Ask an administrator to link it."
              : err.message
          );
        }
      } finally {
        if (!ignore) setSetupLoading(false);
      }
    }

    setup();
    return () => {
      ignore = true;
    };
  }, [mode, accessToken, signOut]);

  const load = useCallback(async () => {
    if (!doctorId) return;
    try {
      if (mode === "doctor") {
        const [dashboard, result] = await Promise.all([
          getDoctorDashboard(accessToken),
          getDoctorQueue(accessToken, doctorId, { limit: LIST_LIMIT }),
        ]);
        setDoctorSummary(dashboard);
        setQueue({ ...result, currentToken: dashboard.currentToken, date: dashboard.date });
        setQueueState(result?.queueState ?? dashboard?.queueState ?? null);
      } else {
        const result = await getDoctorQueue(accessToken, doctorId, { limit: LIST_LIMIT });
        setQueue(result);
        setQueueState(result?.queueState ?? null);
      }
      setUpdatedAt(new Date());
      setError("");
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut();
        return;
      }
      setError(ACTION_MESSAGES[err.code] ?? err.message);
    } finally {
      setLoading(false);
    }
  }, [accessToken, doctorId, mode, signOut]);

  const loadSummary = useCallback(async () => {
    if (mode !== "staff") return;
    try {
      setSummary(await getDashboardSummary(accessToken));
    } catch (err) {
      if (err.code === "UNAUTHORIZED") signOut();
    }
  }, [mode, accessToken, signOut]);

  useEffect(() => {
    if (!doctorId) return;
    load();
    const timer = setInterval(load, REFRESH_MS);
    return () => clearInterval(timer);
  }, [doctorId, load]);

  useEffect(() => {
    if (mode !== "staff") return;
    loadSummary();
    const timer = setInterval(loadSummary, REFRESH_MS);
    return () => clearInterval(timer);
  }, [mode, loadSummary]);

  function changeDoctor(id) {
    setQueue(null);
    setQueueState(null);
    setLoading(true);
    setError("");
    setConfirmSkip(false);
    setSearchParams({ doctor: id }, { replace: true });
  }

  async function run(action) {
    setActing(true);
    setError("");
    setConfirmSkip(false);
    try {
      await action();
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut();
        return;
      }
      setError(ACTION_MESSAGES[err.code] ?? err.message);
    }
    await load();
    loadSummary();
    setActing(false);
  }

  async function handlePauseConfirm(reason) {
    setShowPauseModal(false);
    await run(async () => {
      const res = await pauseDoctorQueue(accessToken, doctorId, reason);
      if (res?.queueState) setQueueState(res.queueState);
    });
  }

  async function handleResumeClick() {
    await run(async () => {
      const res = await resumeDoctorQueue(accessToken, doctorId);
      if (res?.queueState) setQueueState(res.queueState);
    });
  }

  const isPaused = queueState?.paused === true || (!queueState && doctor?.queuePaused === true);
  const pauseReason = queueState?.reason || doctor?.queuePauseReason;
  const pauseReasonText =
    pauseReason === "temporary_delay" ? "Temporary Delay" : "Doctor on Break";
  const pausedTime = queueState?.pausedAt || doctor?.queuePausedAt;

  const current = queue?.currentToken ?? null;
  const waiting = queue?.tokens ?? [];
  const waitingLabel = `${waiting.length}${waiting.length === LIST_LIMIT ? "+" : ""}`;

  let body;
  if (setupLoading) {
    body = <Skeleton />;
  } else if (setupError) {
    body = (
      <p role="alert" className="rounded-2xl bg-red-50 p-5 text-red-700">
        Couldn't load the dashboard. {setupError}
      </p>
    );
  } else if (isAll && doctors.length > 0) {
    body = <AllDoctorsOverview doctors={doctors} onSelect={changeDoctor} />;
  } else if (!doctorId) {
    body = (
      <p className="rounded-2xl bg-white/80 p-8 text-center text-slate-600">
        {mode === "doctor"
          ? "No doctor profile is linked to your account yet. Ask an administrator to link it."
          : "No doctors are listed yet. An administrator needs to add doctors first."}
      </p>
    );
  } else if (loading && !queue) {
    body = <Skeleton />;
  } else if (!queue) {
    body = (
      <p role="alert" className="rounded-2xl bg-red-50 p-5 text-red-700">
        {error || "Couldn't load this queue."}
      </p>
    );
  } else {
    body = (
      <>
        {error && (
          <p role="alert" className="mb-5 rounded-xl bg-red-50 p-3 text-sm text-red-700">
            {error}
          </p>
        )}

        {/* Prominent Paused Banner */}
        {isPaused && (
          <div className="mb-6 flex flex-wrap items-center justify-between gap-4 rounded-3xl bg-amber-500/10 border-2 border-amber-500/30 p-5 backdrop-blur-md shadow-lg shadow-amber-950/5">
            <div className="flex items-start gap-3.5">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-amber-500 text-white shadow-md shadow-amber-500/30">
                <PauseCircle className="h-6 w-6" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-bold text-amber-950">Queue Paused</h3>
                  <span className="rounded-full bg-amber-200/80 px-2.5 py-0.5 text-xs font-bold text-amber-900 uppercase tracking-wide">
                    {pauseReasonText}
                  </span>
                </div>
                <p className="mt-1 text-xs text-amber-800">
                  {pausedTime
                    ? `Paused since ${fmtTime(pausedTime)} (${timeAgo(pausedTime)})`
                    : "Consultations temporarily suspended"} · Calling next patients is disabled until resumed.
                </p>
              </div>
            </div>
            <button
              type="button"
              disabled={acting}
              onClick={handleResumeClick}
              className="inline-flex items-center gap-2 rounded-2xl bg-emerald-600 px-5 py-2.5 text-sm font-semibold text-white shadow-md shadow-emerald-700/20 hover:bg-emerald-700 transition-all disabled:opacity-60"
            >
              <Play className="h-4 w-4" />
              Resume Queue
            </button>
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-5">
          {/* Now serving */}
          <section className="rounded-3xl bg-white/90 backdrop-blur-md p-6 shadow-xl shadow-cyan-950/5 border border-white/70 lg:col-span-2">
            <p className="text-sm font-medium text-slate-500">Now serving</p>

            {current ? (
              <>
                <p className="mt-2 text-6xl font-bold text-primary/70">#{current.tokenNumber}</p>
                <p className="mt-3 text-lg font-semibold text-slate-900">
                  {current.patient?.name ?? "Unknown patient"}
                </p>
                <p className="text-sm text-slate-500">Called at {fmtTime(current.calledAt)}</p>
                {mode === "doctor" &&
                  current.queueDate &&
                  doctorSummary?.date &&
                  current.queueDate !== doctorSummary.date && (
                    <p className="mt-1 text-xs text-slate-500">
                      This consultation was carried over from {current.queueDate}.
                    </p>
                  )}

                <div className="mt-6 space-y-3">
                  <button
                    type="button"
                    disabled={acting}
                    onClick={() => run(() => completeToken(accessToken, doctorId, current._id))}
                    className="flex w-full items-center justify-center gap-2 rounded-xl bg-primary/70 px-5 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80 disabled:opacity-60"
                  >
                    <Check className="h-5 w-5" />
                    Complete consultation
                  </button>

                  {confirmSkip ? (
                    <div className="rounded-xl bg-orange-50 p-3 text-sm text-orange-900">
                      <p>Mark this patient as absent? They'll need to join the queue again.</p>
                      <div className="mt-3 flex gap-3">
                        <button
                          type="button"
                          disabled={acting}
                          onClick={() => run(() => skipToken(accessToken, doctorId, current._id))}
                          className="rounded-lg bg-orange-600 px-4 py-1.5 font-medium text-white hover:bg-orange-700 disabled:opacity-60"
                        >
                          Yes, skip
                        </button>
                        <button
                          type="button"
                          onClick={() => setConfirmSkip(false)}
                          className="rounded-lg border border-orange-300 px-4 py-1.5 font-medium hover:bg-orange-100"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : (
                    <button
                      type="button"
                      disabled={acting}
                      onClick={() => setConfirmSkip(true)}
                      className="flex w-full items-center justify-center gap-2 rounded-xl border border-slate-300 px-5 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-60"
                    >
                      <SkipForward className="h-4 w-4" />
                      Skip (patient absent)
                    </button>
                  )}
                </div>
              </>
            ) : (
              <>
                <p className="mt-3 text-slate-600">No patient is being served right now.</p>
                <button
                  type="button"
                  disabled={acting || waiting.length === 0 || isPaused}
                  onClick={() => run(() => callNext(accessToken, doctorId))}
                  className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-primary/70 px-5 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  <PhoneCall className="h-5 w-5" />
                  {isPaused
                    ? "Queue is paused"
                    : waiting.length === 0
                    ? "No patients waiting"
                    : "Call next patient"}
                </button>
                {isPaused && (
                  <p className="mt-2 text-center text-xs text-amber-700 font-medium">
                    Resume queue above to call the next patient.
                  </p>
                )}
              </>
            )}
          </section>

          {/* Waiting list */}
          <section className="rounded-3xl bg-white/90 backdrop-blur-md p-6 shadow-xl shadow-cyan-950/5 border border-white/70 lg:col-span-3">
            <div className="flex items-baseline justify-between gap-4">
              <h2 className="text-lg font-semibold text-slate-900">Waiting ({waitingLabel})</h2>
              {current && (
                <p className="text-xs text-slate-500">Finish the current consultation to call the next patient.</p>
              )}
            </div>

            {waiting.length === 0 ? (
              <p className="mt-6 rounded-2xl bg-secondary/5 p-6 text-center text-slate-600">
                No patients are waiting.
              </p>
            ) : (
              <ol className="mt-4 space-y-2">
                {waiting.map((t, i) => (
                  <li
                    key={t._id}
                    className={`flex items-center gap-4 rounded-2xl p-3 ${i === 0 ? "bg-primary/5" : "bg-slate-50"}`}
                  >
                    <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-white text-lg font-bold text-primary/80 shadow-sm">
                      #{t.tokenNumber}
                    </span>
                    <span className="min-w-0 flex-1 truncate font-medium text-slate-800">
                      {t.patient?.name ?? "Unknown patient"}
                    </span>
                    {i === 0 && (
                      <span className="rounded-full bg-primary/70 px-2.5 py-0.5 text-xs font-medium text-white">
                        Next
                      </span>
                    )}
                    <span className="text-xs text-slate-500">Joined {fmtTime(t.createdAt)}</span>
                  </li>
                ))}
              </ol>
            )}

            {waiting.length === LIST_LIMIT && (
              <p className="mt-3 text-xs text-slate-500">Showing the first {LIST_LIMIT} waiting patients.</p>
            )}
          </section>
        </div>
      </>
    );
  }

  return (
    <div className="min-h-screen bg-transparent">
      <Navbar />

      <main className="mx-auto max-w-6xl px-6 pb-20 pt-6">
        <header className="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="mb-1 text-base font-medium text-primary/70">
              {queue?.date ? `Today · ${queue.date}` : "Today"}
            </p>
            <h1 className="text-3xl font-bold text-slate-900">
              {mode === "doctor" ? "My queue" : "Queue management"}
            </h1>
            {mode === "doctor" && doctor && (
              <p className="mt-1 text-slate-600">
                {doctor.name}
                {doctor.specialization ? ` · ${doctor.specialization}` : ""}
                {doctor.isAvailable === false ? " · Not accepting bookings" : ""}
              </p>
            )}
            {mode === "staff" && !isAll && doctors.length > 0 && (
              <button
                type="button"
                onClick={() => changeDoctor("all")}
                className="mt-1 text-sm font-medium text-primary/70 hover:underline"
              >
                ← All doctors
              </button>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-4">
            {mode === "staff" && doctors.length > 0 && (
              <div>
                <label htmlFor="doctor" className="mb-1 block text-xs font-medium text-slate-600">
                  Doctor
                </label>
                <select
                  id="doctor"
                  value={selection}
                  onChange={(e) => changeDoctor(e.target.value)}
                  className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/40"
                >
                  <option value="all">All doctors</option>
                  {doctors.map((d) => (
                    <option key={d._id} value={d._id}>
                      {d.name} · {d.specialization}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {/* Pause / Resume Controls in Header */}
            {doctorId && queue && (
              <div className="flex items-center gap-2">
                {isPaused ? (
                  <button
                    type="button"
                    disabled={acting}
                    onClick={handleResumeClick}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-emerald-700 transition-colors disabled:opacity-60"
                  >
                    <Play className="h-4 w-4" />
                    Resume Queue
                  </button>
                ) : (
                  <button
                    type="button"
                    disabled={acting}
                    onClick={() => setShowPauseModal(true)}
                    className="inline-flex items-center gap-1.5 rounded-xl border border-amber-300 bg-amber-50 px-4 py-2 text-sm font-semibold text-amber-800 shadow-sm hover:bg-amber-100 transition-colors disabled:opacity-60"
                  >
                    <Pause className="h-4 w-4" />
                    Pause Queue
                  </button>
                )}

                <button
                  type="button"
                  onClick={load}
                  className="inline-flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-600 shadow-sm hover:text-primary/70"
                >
                  <RefreshCw className={`h-4 w-4 ${acting ? "animate-spin" : ""}`} />
                  {updatedAt ? `Updated ${updatedAt.toLocaleTimeString()}` : "Refresh"}
                </button>
              </div>
            )}
          </div>
        </header>

        {mode === "staff" && summary && <SummaryStrip summary={summary} />}
        {mode === "doctor" && doctorSummary && <DoctorSummaryStrip summary={doctorSummary} />}

        {body}

        {/* Reason selector modal */}
        <PauseQueueModal
          isOpen={showPauseModal}
          onClose={() => setShowPauseModal(false)}
          onConfirm={handlePauseConfirm}
          busy={acting}
        />
      </main>
    </div>
  );
}
