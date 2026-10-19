// src/pages/QueueDashboard.jsx
// One dashboard for two roles:
//   mode="staff"  -> admin / receptionist: pick any doctor and manage their queue
//   mode="doctor" -> doctor: manage only their own queue
import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { PhoneCall, Check, SkipForward, RefreshCw } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import { useAuth } from "../components/context/AuthContext";
import { getDoctors } from "../api/hospital";
import { getDoctorQueue, callNext, completeToken, skipToken } from "../api/staff";

const REFRESH_MS = 10000;
const LIST_LIMIT = 50; // the API's maximum page size

const ACTION_MESSAGES = {
  QUEUE_BUSY: "Another patient is already being served. The queue has been refreshed.",
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

export default function QueueDashboard({ mode }) {
  const { token: accessToken, signOut } = useAuth();
  const [searchParams, setSearchParams] = useSearchParams();

  // Setup: doctor list (and, for doctors, finding their own profile)
  const [doctors, setDoctors] = useState([]);
  const [ownDoctorId, setOwnDoctorId] = useState(null);
  const [setupLoading, setSetupLoading] = useState(true);
  const [setupError, setSetupError] = useState("");

  // Queue
  const [queue, setQueue] = useState(null); // { tokens, currentToken, date }
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [updatedAt, setUpdatedAt] = useState(null);
  const [acting, setActing] = useState(false);
  const [confirmSkip, setConfirmSkip] = useState(false);

  const doctorId = mode === "doctor" ? ownDoctorId : searchParams.get("doctor") || doctors[0]?._id;
  const doctor = doctors.find((d) => d._id === doctorId);

  useEffect(() => {
    let ignore = false;

    async function setup() {
      try {
        const list = await getDoctors({ limit: LIST_LIMIT });
        if (ignore) return;
        setDoctors(list);

        if (mode === "doctor") {
          // The API has no "my doctor profile" endpoint. A doctor gets 403 for every queue except
          // their own, so try each profile until one works.
          // Better long-term: ask the backend for GET /api/doctors/me.
          for (const d of list) {
            try {
              await getDoctorQueue(accessToken, d._id, { limit: 1 });
              if (!ignore) setOwnDoctorId(d._id);
              break;
            } catch (err) {
              if (err.code === "UNAUTHORIZED") {
                signOut();
                return;
              }
              if (err.status !== 403) throw err; // 403 = someone else's queue, keep looking
            }
          }
        }
      } catch (err) {
        if (!ignore) setSetupError(err.message);
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
      const result = await getDoctorQueue(accessToken, doctorId, { limit: LIST_LIMIT });
      setQueue(result);
      setUpdatedAt(new Date());
      setError("");
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut(); // session expired: ProtectedRoute sends the user to login
        return;
      }
      setError(ACTION_MESSAGES[err.code] ?? err.message);
    } finally {
      setLoading(false);
    }
  }, [accessToken, doctorId, signOut]);

  // Load now, then keep the screen fresh.
  useEffect(() => {
    if (!doctorId) return;
    load();
    const timer = setInterval(load, REFRESH_MS);
    return () => clearInterval(timer);
  }, [doctorId, load]);

  function changeDoctor(id) {
    setQueue(null);
    setLoading(true);
    setError("");
    setConfirmSkip(false);
    setSearchParams({ doctor: id }, { replace: true });
  }

  // Run an action, then always refresh. The API docs say to refresh after an action,
  // including a failed or lost one, before retrying.
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
    setActing(false);
  }

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

        <div className="grid gap-6 lg:grid-cols-5">
          {/* Now serving */}
          <section className="rounded-3xl bg-white/95 p-6 shadow-xl lg:col-span-2">
            <p className="text-sm font-medium text-slate-500">Now serving</p>

            {current ? (
              <>
                <p className="mt-2 text-6xl font-bold text-primary/70">#{current.tokenNumber}</p>
                <p className="mt-3 text-lg font-semibold text-slate-900">
                  {current.patient?.name ?? "Unknown patient"}
                </p>
                <p className="text-sm text-slate-500">Called at {fmtTime(current.calledAt)}</p>

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
                  disabled={acting || waiting.length === 0}
                  onClick={() => run(() => callNext(accessToken, doctorId))}
                  className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-primary/70 px-5 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  <PhoneCall className="h-5 w-5" />
                  {waiting.length === 0 ? "No patients waiting" : "Call next patient"}
                </button>
              </>
            )}
          </section>

          {/* Waiting list */}
          <section className="rounded-3xl bg-white/95 p-6 shadow-xl lg:col-span-3">
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
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white">
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
                {doctor.name} · {doctor.specialization}
              </p>
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
                  value={doctorId ?? ""}
                  onChange={(e) => changeDoctor(e.target.value)}
                  className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/50/40"
                >
                  {doctors.map((d) => (
                    <option key={d._id} value={d._id}>
                      {d.name} · {d.specialization}
                    </option>
                  ))}
                </select>
              </div>
            )}
            {doctorId && queue && (
              <button
                type="button"
                onClick={load}
                className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-primary/70"
              >
                <RefreshCw className="h-4 w-4" />
                {updatedAt ? `Updated ${updatedAt.toLocaleTimeString()}` : "Refresh"}
              </button>
            )}
          </div>
        </header>

        {body}
      </main>
    </div>
  );
}