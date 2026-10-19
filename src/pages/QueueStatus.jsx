// src/pages/QueueStatus.jsx — one token: position, estimated wait, cancel. Refreshes automatically.
import { useCallback, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Users, Hourglass, RefreshCw, Info } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import StatusBadge from "../components/queue/StatusBadge";
import { useAuth } from "../components/context/AuthContext";
import { getTokenStatus, cancelToken } from "../api/queue";
import { getDoctor } from "../api/hospital";

const REFRESH_MS = 15000;

const END_MESSAGES = {
  called: { style: "bg-primary/5 text-primary/90", text: "You've been called. Please go to the doctor now." },
  completed: { style: "bg-green-50 text-green-900", text: "Your consultation is complete. Thank you for visiting." },
  cancelled: { style: "bg-slate-100 text-slate-700", text: "You cancelled this token." },
  skipped: {
    style: "bg-orange-50 text-orange-900",
    text: "Your turn was skipped. Please check with the reception desk, or join the queue again.",
  },
};

function Stat({ icon: Icon, label, value, hint }) {
  return (
    <div className="rounded-2xl bg-secondary/5 p-4">
      <div className="flex items-center gap-2 text-sm text-slate-600">
        <Icon className="h-4 w-4 text-primary/70" />
        {label}
      </div>
      <p className="mt-1 text-2xl font-bold text-slate-900">{value}</p>
      {hint && <p className="mt-1 text-xs text-slate-500">{hint}</p>}
    </div>
  );
}

export default function QueueStatus() {
  const { tokenId } = useParams();
  const { token: accessToken, signOut } = useAuth();

  const [data, setData] = useState(null); // { token, peopleAhead, estimatedWaitMinutes, ... }
  const [doctor, setDoctor] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [updatedAt, setUpdatedAt] = useState(null);
  const [confirming, setConfirming] = useState(false);
  const [cancelling, setCancelling] = useState(false);

  const load = useCallback(async () => {
    try {
      const result = await getTokenStatus(accessToken, tokenId);
      setData(result);
      setUpdatedAt(new Date());
      setError("");
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut(); // session expired: ProtectedRoute sends the user to login
        return;
      }
      setError(err.status === 404 ? "We couldn't find that token." : err.message);
    } finally {
      setLoading(false);
    }
  }, [accessToken, tokenId, signOut]);

  useEffect(() => {
    load();
  }, [load]);

  // Keep refreshing while the token is still live (waiting or called).
  const live = data?.token.status === "waiting" || data?.token.status === "called";
  useEffect(() => {
    if (!live) return;
    const timer = setInterval(load, REFRESH_MS);
    return () => clearInterval(timer);
  }, [live, load]);

  // The status response only has the doctor's ID, so fetch the profile for the name.
  const doctorId = data?.token.doctor;
  useEffect(() => {
    if (!doctorId) return;
    let ignore = false;
    getDoctor(doctorId)
      .then((d) => !ignore && setDoctor(d))
      .catch(() => {}); // the name is optional
    return () => {
      ignore = true;
    };
  }, [doctorId]);

  async function handleCancel() {
    setCancelling(true);
    setError("");
    try {
      await cancelToken(accessToken, tokenId);
      await load();
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut();
        return;
      }
      setError(err.message);
      if (err.code === "TOKEN_NOT_CANCELLABLE") await load(); // e.g. you were just called
    } finally {
      setConfirming(false);
      setCancelling(false);
    }
  }

  const t = data?.token;
  const end = t ? END_MESSAGES[t.status] : null;
  const est = data?.estimatedWaitMinutes;
  const waitText = est == null ? "Not available" : est === 0 ? "No delay expected" : `About ${est} min`;
  const date = t
    ? new Date(`${t.queueDate}T00:00:00`).toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
        year: "numeric",
      })
    : "";

  return (
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white">
      <Navbar />

      <main className="mx-auto max-w-2xl px-6 pb-20 pt-6">
        <Link to="/queue" className="text-sm font-medium text-primary/70 hover:underline">
          ← My Queue
        </Link>

        {loading ? (
          <div className="mt-4 h-80 animate-pulse rounded-3xl bg-white/70" />
        ) : !t ? (
          <div role="alert" className="mt-4 rounded-2xl bg-red-50 p-5 text-red-700">
            <p>{error || "Something went wrong."}</p>
            <button
              type="button"
              onClick={() => {
                setLoading(true);
                load();
              }}
              className="mt-3 rounded-lg border border-red-300 px-4 py-1.5 text-sm font-medium hover:bg-red-100"
            >
              Retry
            </button>
          </div>
        ) : (
          <div className="mt-4 rounded-3xl bg-white/95 p-6 shadow-xl sm:p-8">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm text-slate-500">Your token</p>
                <p className="text-5xl font-bold text-slate-900">#{t.tokenNumber}</p>
              </div>
              <StatusBadge status={t.status} />
            </div>

            <div className="mt-4 text-slate-700">
              {doctor && (
                <p className="font-semibold">
                  {doctor.name}
                  <span className="font-normal text-slate-500"> · {doctor.specialization}</span>
                </p>
              )}
              <p className="text-sm text-slate-500">{date}</p>
            </div>

            {error && (
              <p role="alert" className="mt-4 rounded-xl bg-red-50 p-3 text-sm text-red-700">
                {error}
              </p>
            )}

            {end && <p className={`mt-6 rounded-2xl p-4 ${end.style}`}>{end.text}</p>}

            {t.status === "waiting" && (
              <>
                <div className="mt-6 grid gap-4 sm:grid-cols-2">
                  <Stat
                    icon={Users}
                    label="Patients ahead of you"
                    value={data.peopleAhead ?? "—"}
                  />
                  <Stat
                    icon={Hourglass}
                    label="Estimated wait"
                    value={waitText}
                    hint={
                      data.averageConsultationMinutes
                        ? `Based on about ${data.averageConsultationMinutes} min per patient`
                        : undefined
                    }
                  />
                </div>

                {data.consultationOverdue && (
                  <p className="mt-4 rounded-xl bg-yellow-50 p-3 text-sm text-yellow-900">
                    The current consultation is taking longer than usual, so your wait may be longer.
                  </p>
                )}

                <p className="mt-4 flex items-start gap-2 text-xs text-slate-500">
                  <Info className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                  This is an estimate based on the doctor's average consultation time, not an exact
                  appointment time. It refreshes automatically every 15 seconds.
                </p>
              </>
            )}

            <div className="mt-6 flex flex-wrap items-center gap-3 border-t border-slate-100 pt-5">
              {t.status === "waiting" &&
                (confirming ? (
                  <>
                    <span className="text-sm text-slate-700">Cancel this token?</span>
                    <button
                      type="button"
                      onClick={handleCancel}
                      disabled={cancelling}
                      className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60"
                    >
                      {cancelling ? "Cancelling…" : "Yes, cancel"}
                    </button>
                    <button
                      type="button"
                      onClick={() => setConfirming(false)}
                      disabled={cancelling}
                      className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                    >
                      Keep my place
                    </button>
                  </>
                ) : (
                  <button
                    type="button"
                    onClick={() => setConfirming(true)}
                    className="rounded-lg border border-red-300 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-50"
                  >
                    Cancel token
                  </button>
                ))}

              {!live && (
                <Link
                  to="/departments"
                  className="rounded-lg bg-primary/70 px-4 py-2 text-sm font-medium text-white hover:bg-primary/80"
                >
                  Join another queue
                </Link>
              )}

              <button
                type="button"
                onClick={load}
                className="ml-auto inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-primary/70"
              >
                <RefreshCw className="h-4 w-4" />
                {updatedAt ? `Updated ${updatedAt.toLocaleTimeString()}` : "Refresh"}
              </button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}