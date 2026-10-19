// src/pages/MyQueue.jsx — the patient's tokens for today.
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { RefreshCw } from "lucide-react";
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
    <div className="min-h-screen bg-gradient-to-br from-sky-50 via-cyan-50 to-white">
      <Navbar />

      <main className="mx-auto max-w-2xl px-6 pb-20 pt-6">
        <div className="mb-6 flex items-end justify-between gap-4">
          <div>
            <p className="mb-1 text-base font-medium text-teal-700">Today</p>
            <h1 className="text-3xl font-bold text-slate-900">My Queue</h1>
          </div>
          <button
            type="button"
            onClick={() => {
              setLoading(true);
              load();
            }}
            className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-teal-700"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
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
          <div className="rounded-2xl bg-white/80 p-8 text-center">
            <p className="text-slate-600">You haven't joined any queue today.</p>
            <Link
              to="/departments"
              className="mt-4 inline-block rounded-xl bg-teal-700 px-6 py-2.5 text-sm font-medium text-white hover:bg-teal-800"
            >
              Find a doctor
            </Link>
          </div>
        ) : (
          <ul className="space-y-4">
            {tokens.map((t) => (
              <li key={t._id}>
                <Link
                  to={`/queue/${t._id}`}
                  className="flex items-center gap-4 rounded-2xl bg-white/90 p-5 shadow-md transition hover:shadow-lg"
                >
                  <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-teal-50 text-xl font-bold text-teal-800">
                    #{t.tokenNumber}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-semibold text-slate-900">
                      {t.doctor?.name ?? "Doctor no longer listed"}
                    </p>
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