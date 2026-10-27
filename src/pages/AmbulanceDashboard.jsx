import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Info } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import AmbulanceMap from "../components/ambulance/AmbulanceMap";
import { AmbulanceCard, RequestCard, AddAmbulanceForm } from "../components/ambulance/AmbulancePanels";
import { useAuth } from "../components/context/AuthContext";
import {
  listAmbulances,
  createAmbulance,
  updateAmbulance,
  listAmbulanceRequests,
  assignRequest,
  completeRequest,
  cancelRequest,
} from "../api/ambulance";

const REFRESH_MS = 10000;
const LIST_LIMIT = 50; // the API's maximum page size

const ACTION_MESSAGES = {
  AMBULANCE_UNAVAILABLE: "That ambulance is no longer available. The lists have been refreshed.",
  REQUEST_CONFLICT: "That request has already changed. The lists have been refreshed.",
  AMBULANCE_ASSIGNED: "That ambulance is on an active request. Complete or cancel the request first.",
  REQUEST_NOT_FOUND: "That request no longer exists.",
  AMBULANCE_NOT_FOUND: "That ambulance no longer exists.",
  RATE_LIMITED: "Too many changes in a short time. Please wait a few minutes.",
  FORBIDDEN: "Your account can't do that.",
};

const LEGEND = [
  { label: "Available", color: "#16a34a", square: false },
  { label: "Busy", color: "#ea580c", square: false },
  { label: "Maintenance", color: "#64748b", square: false },
  { label: "Pickup: pending", color: "#dc2626", square: true },
  { label: "Pickup: assigned", color: "#2563eb", square: true },
];

const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

function parseCoords(lat, lng) {
  if (lat.trim() === "" || lng.trim() === "") return null;
  const latitude = Number(lat);
  const longitude = Number(lng);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) return null;
  return { latitude, longitude };
}

function Pill({ label, value, className = "bg-white/90 text-slate-700" }) {
  return (
    <span className={`rounded-full px-3 py-1 shadow-sm ${className}`}>
      <span className="font-semibold">{value}</span> {label}
    </span>
  );
}

export default function AmbulanceDashboard() {
  const { user, token: accessToken, signOut } = useAuth();

  const [ambulances, setAmbulances] = useState([]);
  const [pending, setPending] = useState([]);
  const [assigned, setAssigned] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [updatedAt, setUpdatedAt] = useState(null);

  const [acting, setActing] = useState(false);
  const [notice, setNotice] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [locEdit, setLocEdit] = useState(null); 
  const [focus, setFocus] = useState(null);

  const editorRef = useRef(null);
  const mapRef = useRef(null);

  const load = useCallback(async () => {
    try {
      const [amb, pend, assn] = await Promise.all([
        listAmbulances(accessToken, { limit: LIST_LIMIT }),
        listAmbulanceRequests(accessToken, { status: "pending", limit: LIST_LIMIT }),
        listAmbulanceRequests(accessToken, { status: "assigned", limit: LIST_LIMIT }),
      ]);
      const oldestFirst = [...pend].sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
      setAmbulances((prev) => (same(prev, amb) ? prev : amb));
      setPending((prev) => (same(prev, oldestFirst) ? prev : oldestFirst));
      setAssigned((prev) => (same(prev, assn) ? prev : assn));
      setUpdatedAt(new Date());
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
    const timer = setInterval(load, REFRESH_MS);
    return () => clearInterval(timer);
  }, [load]);

  const activeAmbulanceIds = useMemo(
    () => new Set(assigned.map((r) => r.ambulance?._id).filter(Boolean)),
    [assigned]
  );
  const availableAmbulances = useMemo(
    () => ambulances.filter((a) => a.status === "available" && !activeAmbulanceIds.has(a._id)),
    [ambulances, activeAmbulanceIds]
  );
  const activeRequests = useMemo(() => [...pending, ...assigned], [pending, assigned]);
  const countOf = (status) => ambulances.filter((a) => a.status === status).length;

  async function run(action) {
    setActing(true);
    setNotice("");
    let ok = true;
    try {
      await action();
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut();
        return false;
      }
      setNotice(ACTION_MESSAGES[err.code] ?? err.message);
      ok = false;
    }
    await load();
    setActing(false);
    return ok;
  }

  const handleStatus = (a, status) => run(() => updateAmbulance(accessToken, a._id, { status }));
  const handleAssign = (requestId, ambulanceId) => run(() => assignRequest(accessToken, requestId, ambulanceId));
  const handleComplete = (id) => run(() => completeRequest(accessToken, id));
  const handleCancel = (id) => run(() => cancelRequest(accessToken, id));

  async function handleCreate(body) {
    await createAmbulance(accessToken, body);
    await load();
  }

  function show(lat, lng) {
    setFocus({ lat, lng, key: Date.now() });
    mapRef.current?.scrollIntoView({ behavior: "smooth", block: "center" });
  }

  // ---- Updating a location ----
  function startEdit(a) {
    const loc = a.location;
    setLocEdit({
      ambulance: a,
      lat: loc ? String(loc.latitude) : "",
      lng: loc ? String(loc.longitude) : "",
    });
    if (loc) setFocus({ lat: loc.latitude, lng: loc.longitude, key: Date.now() });
  }

  const handlePick = useCallback((lat, lng) => {
    setLocEdit((prev) => (prev ? { ...prev, lat: lat.toFixed(6), lng: lng.toFixed(6) } : prev));
  }, []);

  const coords = locEdit ? parseCoords(locEdit.lat, locEdit.lng) : null;
  const pickLat = coords?.latitude ?? null;
  const pickLng = coords?.longitude ?? null;
  const pickedPoint = useMemo(
    () => (pickLat === null ? null : { lat: pickLat, lng: pickLng }),
    [pickLat, pickLng]
  );

  const editingId = locEdit?.ambulance._id;
  useEffect(() => {
    if (editingId) editorRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
  }, [editingId]);

  async function saveLocation() {
    if (!coords) return;
    const ok = await run(() => updateAmbulance(accessToken, locEdit.ambulance._id, { location: coords }));
    if (ok) setLocEdit(null);
  }

  const hasData = updatedAt !== null;
  const inputClass =
    "w-36 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/40";

  return (
    <div className="min-h-screen bg-transparent">
      <Navbar />

      <main className="mx-auto max-w-6xl px-6 pb-20 pt-6">
        <header className="mb-5 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="mb-1 text-base font-medium text-primary/70">Staff</p>
            <h1 className="text-3xl font-bold text-slate-900">Ambulance tracking</h1>
          </div>
          <div className="flex items-center gap-4">
            {updatedAt && <span className="text-xs text-slate-500">Updated {updatedAt.toLocaleTimeString()}</span>}
            {user.role === "admin" && !showAdd && (
              <button
                type="button"
                onClick={() => setShowAdd(true)}
                className="rounded-xl bg-primary/70 px-5 py-2 text-sm font-medium text-white shadow-sm hover:bg-primary/80"
              >
                Add ambulance
              </button>
            )}
          </div>
        </header>

        {hasData && (
          <div className="mb-6 flex flex-wrap gap-3 text-sm">
            <Pill
              label="pending requests"
              value={pending.length}
              className={pending.length > 0 ? "bg-red-100 text-red-800" : "bg-white/90 text-slate-700"}
            />
            <Pill label="assigned" value={assigned.length} />
            <Pill label="available" value={countOf("available")} className="bg-green-100 text-green-800" />
            <Pill label="busy" value={countOf("busy")} className="bg-orange-100 text-orange-800" />
            <Pill label="maintenance" value={countOf("maintenance")} />
          </div>
        )}

        {showAdd && <AddAmbulanceForm onCreate={handleCreate} onClose={() => setShowAdd(false)} />}

        {notice && (
          <p role="alert" className="mb-5 rounded-xl bg-red-50 p-3 text-sm text-red-700">
            {notice}
          </p>
        )}

        {error && hasData && (
          <p role="alert" className="mb-5 rounded-xl bg-yellow-50 p-3 text-sm text-yellow-900">
            Couldn't refresh ({error}). Showing the last data we have.
          </p>
        )}

        {locEdit && (
          <section ref={editorRef} aria-label="Update location" className="mb-6 scroll-mt-4 rounded-2xl bg-primary/5 p-5">
            <p className="font-semibold text-slate-900">Update location · {locEdit.ambulance.vehicleNumber}</p>
            <p className="mt-1 text-sm text-slate-600">
              Click the map to place the ambulance, or type the coordinates.
            </p>
            <div className="mt-4 flex flex-wrap items-end gap-3">
              <div>
                <label htmlFor="loc-lat" className="mb-1 block text-xs font-medium text-slate-600">
                  Latitude
                </label>
                <input
                  id="loc-lat"
                  inputMode="decimal"
                  value={locEdit.lat}
                  onChange={(e) => setLocEdit((p) => ({ ...p, lat: e.target.value }))}
                  className={inputClass}
                />
              </div>
              <div>
                <label htmlFor="loc-lng" className="mb-1 block text-xs font-medium text-slate-600">
                  Longitude
                </label>
                <input
                  id="loc-lng"
                  inputMode="decimal"
                  value={locEdit.lng}
                  onChange={(e) => setLocEdit((p) => ({ ...p, lng: e.target.value }))}
                  className={inputClass}
                />
              </div>
              <button
                type="button"
                disabled={!coords || acting}
                onClick={saveLocation}
                className="rounded-xl bg-primary/70 px-5 py-2 text-sm font-medium text-white hover:bg-primary/80 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Save location
              </button>
              <button
                type="button"
                onClick={() => setLocEdit(null)}
                className="rounded-xl border border-slate-300 px-5 py-2 text-sm font-medium text-slate-700 hover:bg-white"
              >
                Cancel
              </button>
            </div>
            {(locEdit.lat || locEdit.lng) && !coords && (
              <p className="mt-2 text-xs text-red-600">
                Enter numbers: latitude from -90 to 90 and longitude from -180 to 180.
              </p>
            )}
          </section>
        )}

        {loading ? (
          <div className="grid gap-6 lg:grid-cols-5">
            <div className="h-[28rem] animate-pulse rounded-3xl bg-white/70 lg:col-span-3" />
            <div className="h-[28rem] animate-pulse rounded-3xl bg-white/70 lg:col-span-2" />
          </div>
        ) : !hasData ? (
          <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-red-50 p-5 text-red-700">
            <span>Couldn't load the ambulance data. {error}</span>
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
            <div className="grid gap-6 lg:grid-cols-5">
              {/* Map */}
              <section ref={mapRef} aria-label="Map" className="lg:col-span-3">
                <AmbulanceMap
                  ambulances={ambulances}
                  requests={activeRequests}
                  focus={focus}
                  pickMode={locEdit !== null}
                  onPick={handlePick}
                  pickedPoint={pickedPoint}
                />
                <ul className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-600">
                  {LEGEND.map((item) => (
                    <li key={item.label} className="flex items-center gap-1.5">
                      <span
                        className="inline-block h-3 w-3"
                        style={{ background: item.color, borderRadius: item.square ? "3px" : "50%" }}
                      />
                      {item.label}
                    </li>
                  ))}
                </ul>
                <p className="mt-2 flex items-start gap-2 text-xs text-slate-500">
                  <Info className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                  Ambulance positions are entered by staff, not tracked live. Check the "updated" time before
                  relying on one.
                </p>
              </section>

              {/* Requests */}
              <section aria-label="Requests" className="lg:col-span-2">
                <h2 className="mb-3 text-xl font-semibold text-slate-900">Requests</h2>
                <div className="max-h-[30rem] space-y-3 overflow-y-auto pr-1">
                  {activeRequests.length === 0 && (
                    <p className="rounded-2xl bg-white/80 p-6 text-center text-slate-600">
                      No active requests right now.
                    </p>
                  )}

                  {pending.length > 0 && (
                    <>
                      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Pending · oldest first
                      </p>
                      {pending.map((r) => (
                        <RequestCard
                          key={r._id}
                          request={r}
                          availableAmbulances={availableAmbulances}
                          disabled={acting}
                          onAssign={handleAssign}
                          onComplete={handleComplete}
                          onCancel={handleCancel}
                          onShow={show}
                        />
                      ))}
                    </>
                  )}

                  {assigned.length > 0 && (
                    <>
                      <p className="pt-2 text-xs font-semibold uppercase tracking-wide text-slate-500">Assigned</p>
                      {assigned.map((r) => (
                        <RequestCard
                          key={r._id}
                          request={r}
                          availableAmbulances={availableAmbulances}
                          disabled={acting}
                          onAssign={handleAssign}
                          onComplete={handleComplete}
                          onCancel={handleCancel}
                          onShow={show}
                        />
                      ))}
                    </>
                  )}
                </div>
              </section>
            </div>

            {/* Ambulances */}
            <section aria-label="Ambulances" className="mt-10">
              <h2 className="mb-4 text-xl font-semibold text-slate-900">
                Ambulances ({ambulances.length}
                {ambulances.length === LIST_LIMIT ? "+" : ""})
              </h2>
              {ambulances.length === 0 ? (
                <p className="rounded-2xl bg-white/80 p-8 text-center text-slate-600">
                  {user.role === "admin"
                    ? 'No ambulances yet. Use "Add ambulance" to register one.'
                    : "No ambulances are registered yet. An admin can add them."}
                </p>
              ) : (
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  {ambulances.map((a) => (
                    <AmbulanceCard
                      key={a._id}
                      ambulance={a}
                      onActiveRequest={activeAmbulanceIds.has(a._id)}
                      disabled={acting}
                      onStatus={handleStatus}
                      onEditLocation={startEdit}
                      onShow={show}
                    />
                  ))}
                </div>
              )}
            </section>
          </>
        )}
      </main>
    </div>
  );
}