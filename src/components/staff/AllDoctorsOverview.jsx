// src/components/staff/AllDoctorsOverview.jsx

import { useCallback, useEffect, useRef, useState } from "react";
import { ChevronRight } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { getDoctorQueue } from "../../api/staff";

const REFRESH_MS = 15000;
const LIST_LIMIT = 50; 
const PARALLEL = 6; 

export default function AllDoctorsOverview({ doctors, onSelect }) {
  const { token: accessToken, signOut } = useAuth();
  const [rows, setRows] = useState({}); 
  const [loading, setLoading] = useState(true);
  const [updatedAt, setUpdatedAt] = useState(null);
  const [onlyBusy, setOnlyBusy] = useState(false);
  const running = useRef(false); 

  const load = useCallback(async () => {
    if (running.current) return;
    running.current = true;

    const results = {};
    let expired = false;
    let next = 0;

    async function worker() {
      while (next < doctors.length) {
        const doctor = doctors[next++];
        try {
          const queue = await getDoctorQueue(accessToken, doctor._id, { limit: LIST_LIMIT });
          results[doctor._id] = { waiting: queue.tokens.length, current: queue.currentToken };
        } catch (err) {
          if (err.code === "UNAUTHORIZED") expired = true;
          results[doctor._id] = { error: true };
        }
      }
    }

    try {
      await Promise.all(Array.from({ length: Math.min(PARALLEL, doctors.length) }, worker));
      if (expired) {
        signOut(); // session expired: ProtectedRoute sends the user to login
        return;
      }
      setRows(results);
      setUpdatedAt(new Date());
      setLoading(false);
    } finally {
      running.current = false;
    }
  }, [accessToken, doctors, signOut]);

  useEffect(() => {
    load();
    const timer = setInterval(load, REFRESH_MS);
    return () => clearInterval(timer);
  }, [load]);

  if (loading) {
    return (
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 6 }, (_, i) => (
          <div key={i} className="h-32 animate-pulse rounded-2xl bg-white/70" />
        ))}
      </div>
    );
  }

  const values = Object.values(rows);
  const totalWaiting = values.reduce((sum, r) => sum + (r.waiting ?? 0), 0);
  const capped = values.some((r) => r.waiting === LIST_LIMIT);
  const beingServed = values.filter((r) => r.current).length;
  const failed = values.filter((r) => r.error).length;

  const isBusy = (r) => r && (r.waiting > 0 || r.current);
  const visible = onlyBusy ? doctors.filter((d) => isBusy(rows[d._id])) : doctors;

  return (
    <section aria-label="All doctors">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-slate-600">
          <span className="font-semibold text-slate-900">
            {totalWaiting}
            {capped ? "+" : ""}
          </span>{" "}
          waiting ·{" "}
          <span className="font-semibold text-slate-900">{beingServed}</span> being served · across{" "}
          {doctors.length} doctors
        </p>
        <div className="flex items-center gap-4">
          <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-700">
            <input
              type="checkbox"
              checked={onlyBusy}
              onChange={(e) => setOnlyBusy(e.target.checked)}
              className="h-4 w-4 accent-primary/70"
            />
            Only doctors with patients
          </label>
          <span className="text-xs text-slate-500">
            {updatedAt ? `Updated ${updatedAt.toLocaleTimeString()}` : ""}
          </span>
        </div>
      </div>

      {failed > 0 && (
        <p role="alert" className="mb-4 rounded-xl bg-red-50 p-3 text-sm text-red-700">
          Couldn't load {failed === 1 ? "one doctor's queue" : `${failed} doctors' queues`}. They'll be
          retried on the next refresh.
        </p>
      )}

      {visible.length === 0 ? (
        <p className="rounded-2xl bg-white/80 p-8 text-center text-slate-600">
          No doctors have patients right now.
        </p>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {visible.map((d) => {
            const row = rows[d._id];
            const current = row?.current;
            return (
              <button
                key={d._id}
                type="button"
                onClick={() => onSelect(d._id)}
                className={`flex flex-col gap-3 rounded-2xl p-4 text-left shadow-md transition hover:shadow-lg ${
                  current ? "bg-primary/5 ring-1 ring-primary/30" : "bg-white/90"
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-slate-900">{d.name}</p>
                    <p className="truncate text-sm text-slate-500">{d.specialization}</p>
                  </div>
                  <ChevronRight className="mt-1 h-4 w-4 shrink-0 text-slate-400" />
                </div>

                {row?.error ? (
                  <p className="text-sm text-red-600">Couldn't load this queue</p>
                ) : (
                  <>
                    <p className="text-sm text-slate-700">
                      {current ? (
                        <>
                          <span className="font-semibold text-primary/80">Serving #{current.tokenNumber}</span>
                          {current.patient?.name ? ` · ${current.patient.name}` : ""}
                        </>
                      ) : (
                        <span className="text-slate-500">No one being served</span>
                      )}
                    </p>
                    <div className="flex items-center gap-2">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          row?.waiting > 0 ? "bg-yellow-100 text-yellow-800" : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {row?.waiting ?? 0}
                        {row?.waiting === LIST_LIMIT ? "+" : ""} waiting
                      </span>
                      {d.isAvailable === false && (
                        <span className="text-xs text-slate-500">Not accepting bookings</span>
                      )}
                    </div>
                  </>
                )}
              </button>
            );
          })}
        </div>
      )}
    </section>
  );
}