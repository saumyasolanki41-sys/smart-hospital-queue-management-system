import { useCallback, useEffect, useState } from "react";
import { Info } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import AmbulanceRequestForm from "../components/ambulance/AmbulanceRequestForm";
import RequestStatusCard from "../components/ambulance/RequestStatusCard";
import { useAuth } from "../components/context/AuthContext";
import { createAmbulanceRequest, listAmbulanceRequests, cancelRequest, getAmbulanceEta } from "../api/ambulance";
import { timeAgo } from "../utils/time";

const HOSPITAL_EMERGENCY_PHONE = "";

const REFRESH_MS = 10000;

const isActive = (r) => r.status === "pending" || r.status === "assigned";

const HISTORY_STYLE = {
  completed: "bg-green-100 text-green-800",
  cancelled: "bg-slate-100 text-slate-700",
};

function EmergencyBanner() {
  return (
    <div role="note" className="mb-6 flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-red-50 p-4 text-red-900">
      <div className="flex min-w-0 flex-1 items-start gap-3 sm:min-w-[18rem]">
        <Info className="mt-0.5 h-5 w-5 shrink-0" />
        <p className="text-sm">
          <span className="font-semibold">Is someone in danger? Call 112 now.</span> This page sends a request to
          hospital staff, who assign an ambulance by hand. It doesn't call an ambulance automatically and can't
          promise a response time.
        </p>
      </div>
      <div className="flex flex-wrap gap-2">
        <a
          href="tel:112"
          className="rounded-xl bg-red-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-red-700"
        >
          Call 112
        </a>
        {HOSPITAL_EMERGENCY_PHONE && (
          <a
            href={`tel:${HOSPITAL_EMERGENCY_PHONE}`}
            className="rounded-xl border border-red-300 px-5 py-2.5 text-sm font-semibold text-red-800 hover:bg-red-100"
          >
            Call the hospital
          </a>
        )}
      </div>
    </div>
  );
}

export default function RequestAmbulance() {
  const { token: accessToken } = useAuth();

  const [requests, setRequests] = useState(null); 
  const [eta, setEta] = useState(null);
  const [etaFailed, setEtaFailed] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [cancelling, setCancelling] = useState(false);

  const load = useCallback(async () => {
    try {
      const list = await listAmbulanceRequests(accessToken, { limit: 20 }); // newest first
      setRequests(list);
      setError("");

      const active = list.find(isActive);
      if (active?.status === "assigned") {
        try {
          setEta(await getAmbulanceEta(accessToken, active._id));
          setEtaFailed(false);
        } catch {
          setEtaFailed(true);
        }
      } else {
        setEta(null);
        setEtaFailed(false);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [accessToken]);

  useEffect(() => {
    load();
  }, [load]);

  
  const active = requests?.find(isActive) ?? null;
  const hasActive = active !== null;
  useEffect(() => {
    if (!hasActive) return;
    const timer = setInterval(load, REFRESH_MS);
    return () => clearInterval(timer);
  }, [hasActive, load]);

  const history = (requests ?? []).filter((r) => !isActive(r)).slice(0, 5);

  async function handleCreate(body) {
    try {
      await createAmbulanceRequest(accessToken, body);
    } catch (err) {
      if (err.code === "ACTIVE_REQUEST_EXISTS") await load(); 
      throw err;
    }
    await load();
  }

  async function handleCancel() {
    setCancelling(true);
    setNotice("");
    try {
      await cancelRequest(accessToken, active._id);
    } catch (err) {
      setNotice(
        err.code === "REQUEST_CONFLICT"
          ? "This request can't be cancelled here any more. An ambulance may already be assigned. Please contact hospital staff."
          : err.code === "RATE_LIMITED"
          ? "Too many changes in a short time. Please wait a few minutes."
          : err.message
      );
    }
    await load();
    setCancelling(false);
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white">
      <Navbar />

      <main className="mx-auto max-w-3xl px-6 pb-20 pt-6">
        <header className="mb-6">
          <p className="mb-1 text-base font-medium text-primary/70">Patient services</p>
          <h1 className="text-3xl font-bold text-slate-900">Ambulance</h1>
        </header>

        <EmergencyBanner />

        {notice && (
          <p role="alert" className="mb-5 rounded-xl bg-red-50 p-3 text-sm text-red-700">
            {notice}
          </p>
        )}

        {loading ? (
          <div className="h-80 animate-pulse rounded-3xl bg-white/70" />
        ) : requests === null ? (
          <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-red-50 p-5 text-red-700">
            <span>Couldn't load your ambulance requests. {error}</span>
            <button
              type="button"
              onClick={() => {
                setLoading(true);
                load();
              }}
              className="rounded-lg border border-red-300 px-4 py-1.5 text-sm font-medium hover:bg-red-100"
            >
              Retry
            </button>
          </div>
        ) : (
          <>
            {error && (
              <p role="alert" className="mb-5 rounded-xl bg-yellow-50 p-3 text-sm text-yellow-900">
                Couldn't refresh ({error}). Showing the last information we have.
              </p>
            )}

            {active ? (
              <RequestStatusCard
                request={active}
                eta={eta}
                etaFailed={etaFailed}
                onCancel={handleCancel}
                cancelling={cancelling}
              />
            ) : (
              <AmbulanceRequestForm onSubmit={handleCreate} />
            )}

            {history.length > 0 && (
              <section aria-label="Past requests" className="mt-10">
                <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">Past requests</h2>
                <ul className="space-y-2">
                  {history.map((r) => (
                    <li key={r._id} className="flex items-center gap-3 rounded-2xl bg-white/80 p-3 text-sm">
                      <span className="min-w-0 flex-1 truncate text-slate-700">{r.pickupAddress}</span>
                      <span className="shrink-0 text-xs text-slate-500">{timeAgo(r.createdAt)}</span>
                      <span
                        className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          HISTORY_STYLE[r.status] ?? HISTORY_STYLE.cancelled
                        }`}
                      >
                        {r.status.charAt(0).toUpperCase() + r.status.slice(1)}
                      </span>
                    </li>
                  ))}
                </ul>
              </section>
            )}
          </>
        )}
      </main>
    </div>
  );
}