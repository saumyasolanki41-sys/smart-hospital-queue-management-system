// src/pages/MyQueue.jsx — the patient's tokens for today.
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { RefreshCw, PauseCircle, History } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import StatusBadge from "../components/queue/StatusBadge";
import { useAuth } from "../components/context/AuthContext";
import { getMyTokens } from "../api/queue";

export default function MyQueue() {
  const { token: accessToken, signOut } = useAuth();
  const [tokens, setTokens] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    try {
      setTokens(await getMyTokens(accessToken));
      setError("");
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut();
        return;
      }
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [accessToken, signOut]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div className="min-h-screen bg-transparent">
      <Navbar />

      <main className="mx-auto max-w-2xl px-6 pb-20 pt-6">
        <div className="mb-6 flex items-end justify-between gap-4">
          <div>
            <p className="mb-1 text-base font-semibold text-[#197092]">Today</p>
            <h1 className="text-3xl font-bold text-slate-900">My Queue</h1>
          </div>
          <div className="flex items-center gap-3">
            <Link
              to="/history"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#197092] hover:underline"
            >
              <History className="h-3.5 w-3.5" />
              Past Visits
            </Link>
            <button
              type="button"
              onClick={() => {
                setLoading(true);
                load();
              }}
              className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-primary/70"
            >
              <RefreshCw className="h-4 w-4" />
              Refresh
            </button>
          </div>
        </div>

        {loading ? (
          <div className="space-y-4">
            {[0, 1].map((i) => (
              <div key={i} className="h-24 animate-pulse rounded-2xl bg-white/70" />
            ))}
          </div>
        ) : error ? (
          <div role="alert" className="rounded-2xl bg-red-50 p-5 text-red-700">
            {error}
          </div>
        ) : tokens.length === 0 ? (
          <div className="rounded-3xl bg-white/90 backdrop-blur-md p-8 text-center shadow-md border border-white/80">
            <p className="text-slate-600">You haven't joined any queue today.</p>
            <div className="mt-4 flex flex-wrap justify-center gap-3">
              <Link
                to="/departments"
                className="rounded-xl bg-[#197092] px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-[#145d7a] transition-colors"
              >
                Find a doctor
              </Link>
              <Link
                to="/history"
                className="rounded-xl border border-slate-200 bg-white px-5 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors"
              >
                View Visit History
              </Link>
            </div>
          </div>
        ) : (
          <ul className="space-y-4">
            {tokens.map((t) => (
              <li key={t._id}>
                <Link
                  to={`/queue/${t._id}`}
                  className="flex items-center gap-4 rounded-3xl bg-white/90 backdrop-blur-md p-5 shadow-md shadow-cyan-950/5 border border-white/80 transition hover:shadow-lg hover:border-cyan-100"
                >
                  <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-cyan-50 text-xl font-bold text-[#197092] border border-cyan-100 shadow-sm">
                    #{t.tokenNumber}
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <p className="truncate font-semibold text-slate-900">
                        {t.doctor?.name ?? "Doctor no longer listed"}
                      </p>
                      {t.doctor?.queuePaused && t.status === "waiting" && (
                        <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-semibold text-amber-800 border border-amber-200">
                          <PauseCircle className="h-3 w-3 text-amber-600" />
                          Paused
                        </span>
                      )}
                    </div>
                    <p className="truncate text-sm text-slate-500">{t.doctor?.specialization}</p>
                  </div>
                  <StatusBadge status={t.status} />
                </Link>
              </li>
            ))}
          </ul>
        )}
      </main>
    </div>
  );
}
