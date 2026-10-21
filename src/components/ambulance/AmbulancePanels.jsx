import { useState } from "react";
import { Phone, MapPin } from "lucide-react";
import { timeAgo, isStale } from "../../utils/time";

const inputClass =
  "w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/40";

const AMBULANCE_STYLE = {
  available: "bg-green-100 text-green-800",
  busy: "bg-orange-100 text-orange-800",
  maintenance: "bg-slate-100 text-slate-700",
};

const REQUEST_STYLE = {
  pending: "bg-red-100 text-red-800",
  assigned: "bg-primary/10 text-primary/80",
};

const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);

export function AmbulanceCard({ ambulance, onActiveRequest, disabled, onStatus, onEditLocation, onShow }) {
  const loc = ambulance.location;
  const stale = loc ? isStale(loc.updatedAt) : false;

  return (
    <article className="flex flex-col gap-3 rounded-2xl bg-white/90 p-4 shadow-md">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="truncate font-semibold text-slate-900">{ambulance.vehicleNumber}</p>
          <p className="truncate text-sm text-slate-500">{ambulance.driverName}</p>
        </div>
        <span
          className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-medium ${
            AMBULANCE_STYLE[ambulance.status] ?? AMBULANCE_STYLE.maintenance
          }`}
        >
          {capitalize(ambulance.status)}
        </span>
      </div>

      <a
        href={`tel:${ambulance.driverPhone}`}
        className="inline-flex items-center gap-2 text-sm text-primary/80 hover:underline"
      >
        <Phone className="h-4 w-4" />
        {ambulance.driverPhone}
      </a>

      <div className="text-sm">
        {loc ? (
          <>
            <p className="text-slate-600">
              {loc.latitude.toFixed(4)}, {loc.longitude.toFixed(4)}
            </p>
            <p className={stale ? "font-medium text-orange-700" : "text-slate-500"}>
              Updated {timeAgo(loc.updatedAt)}
              {stale ? " · may be out of date" : ""}
            </p>
          </>
        ) : (
          <p className="text-slate-500">No location entered yet</p>
        )}
        {onActiveRequest && <p className="mt-1 text-xs font-medium text-primary/80">On an active request</p>}
      </div>

      <div className="mt-auto flex flex-wrap items-center gap-2">
        <select
          aria-label={`Status for ${ambulance.vehicleNumber}`}
          value={ambulance.status}
          disabled={disabled || onActiveRequest}
          title={onActiveRequest ? "Complete or cancel its request to change the status" : undefined}
          onChange={(e) => onStatus(ambulance, e.target.value)}
          className="rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-sm disabled:opacity-60"
        >
          <option value="available">Available</option>
          <option value="busy">Busy</option>
          <option value="maintenance">Maintenance</option>
        </select>
        <button
          type="button"
          onClick={() => onEditLocation(ambulance)}
          className="rounded-lg border border-primary/60 px-3 py-1.5 text-sm font-medium text-primary/70 hover:bg-primary/5"
        >
          Update location
        </button>
        {loc && (
          <button
            type="button"
            onClick={() => onShow(loc.latitude, loc.longitude)}
            className="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-primary/70"
          >
            <MapPin className="h-4 w-4" />
            Map
          </button>
        )}
      </div>
    </article>
  );
}

export function RequestCard({ request, availableAmbulances, disabled, onAssign, onComplete, onCancel, onShow }) {
  const [ambulanceId, setAmbulanceId] = useState("");
  const [confirm, setConfirm] = useState(null); // "complete" | "cancel"
  const pending = request.status === "pending";
  const selected = availableAmbulances.some((a) => a._id === ambulanceId) ? ambulanceId : "";

  return (
    <article className="rounded-2xl bg-white/90 p-4 shadow-md">
      <div className="flex items-start justify-between gap-3">
        <p className="min-w-0 font-semibold text-slate-900">{request.pickupAddress}</p>
        <span
          className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-medium ${
            REQUEST_STYLE[request.status] ?? REQUEST_STYLE.assigned
          }`}
        >
          {capitalize(request.status)}
        </span>
      </div>

      <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-slate-600">
        <a href={`tel:${request.contactPhone}`} className="inline-flex items-center gap-1.5 text-primary/80 hover:underline">
          <Phone className="h-4 w-4" />
          {request.contactPhone}
        </a>
        <span className="text-slate-500">Requested {timeAgo(request.createdAt)}</span>
        <button
          type="button"
          onClick={() => onShow(request.latitude, request.longitude)}
          className="inline-flex items-center gap-1 text-slate-500 hover:text-primary/70"
        >
          <MapPin className="h-4 w-4" />
          Map
        </button>
      </div>

      {!pending && (
        <p className="mt-3 text-sm text-slate-700">
          Assigned to{" "}
          <span className="font-semibold">{request.ambulance?.vehicleNumber ?? "an ambulance"}</span>
          {request.assignedAt ? ` · ${timeAgo(request.assignedAt)}` : ""}
        </p>
      )}

      <div className="mt-3">
        {confirm ? (
          <div className="flex flex-wrap items-center gap-3 rounded-xl bg-slate-50 p-3 text-sm">
            <span className="text-slate-700">
              {confirm === "cancel" ? "Cancel this request?" : "Mark this transport as completed?"}
            </span>
            <button
              type="button"
              disabled={disabled}
              onClick={() => (confirm === "cancel" ? onCancel(request._id) : onComplete(request._id))}
              className="rounded-lg bg-primary/70 px-3 py-1.5 font-medium text-white hover:bg-primary/80 disabled:opacity-60"
            >
              Yes
            </button>
            <button
              type="button"
              onClick={() => setConfirm(null)}
              className="rounded-lg border border-slate-300 px-3 py-1.5 font-medium text-slate-700 hover:bg-white"
            >
              No
            </button>
          </div>
        ) : pending ? (
          <div className="space-y-2">
            {availableAmbulances.length === 0 ? (
              <p className="text-sm text-orange-700">No ambulance is available right now.</p>
            ) : (
              <div className="flex flex-wrap items-center gap-2">
                <select
                  aria-label="Choose an ambulance"
                  value={selected}
                  onChange={(e) => setAmbulanceId(e.target.value)}
                  className="min-w-0 flex-1 rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-sm"
                >
                  <option value="">Choose ambulance…</option>
                  {availableAmbulances.map((a) => (
                    <option key={a._id} value={a._id}>
                      {a.vehicleNumber} · {a.driverName}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  disabled={!selected || disabled}
                  onClick={() => onAssign(request._id, selected)}
                  className="rounded-lg bg-primary/70 px-4 py-1.5 text-sm font-medium text-white hover:bg-primary/80 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  Assign
                </button>
              </div>
            )}
            <button
              type="button"
              onClick={() => setConfirm("cancel")}
              className="text-sm font-medium text-red-700 hover:underline"
            >
              Cancel request
            </button>
          </div>
        ) : (
          <div className="flex flex-wrap items-center gap-3">
            <button
              type="button"
              disabled={disabled}
              onClick={() => setConfirm("complete")}
              className="rounded-lg bg-primary/70 px-4 py-1.5 text-sm font-medium text-white hover:bg-primary/80 disabled:opacity-60"
            >
              Mark completed
            </button>
            <button
              type="button"
              onClick={() => setConfirm("cancel")}
              className="text-sm font-medium text-red-700 hover:underline"
            >
              Cancel request
            </button>
          </div>
        )}
      </div>
    </article>
  );
}

export function AddAmbulanceForm({ onCreate, onClose }) {
  const [form, setForm] = useState({ vehicleNumber: "", driverName: "", driverPhone: "" });
  const [errors, setErrors] = useState({});
  const [serverError, setServerError] = useState("");
  const [saving, setSaving] = useState(false);

  const update = (field) => (e) => setForm((f) => ({ ...f, [field]: e.target.value }));

  function validate() {
    const plate = form.vehicleNumber.replace(/[\s-]/g, "");
    const name = form.driverName.trim();
    return {
      vehicleNumber: /^[A-Za-z0-9]{4,20}$/.test(plate)
        ? ""
        : "Use 4–20 letters or digits (spaces and hyphens are ignored).",
      driverName: name.length >= 2 && name.length <= 100 ? "" : "Name must be 2–100 characters.",
      driverPhone: /^\+?[1-9]\d{9,14}$/.test(form.driverPhone.trim())
        ? ""
        : "Enter 10–15 digits, optionally starting with +, not starting with 0.",
    };
  }

  async function handleSubmit(e) {
    e.preventDefault();
    const found = validate();
    setErrors(found);
    if (Object.values(found).some(Boolean)) return;

    setSaving(true);
    setServerError("");
    try {
      await onCreate({
        vehicleNumber: form.vehicleNumber.trim(),
        driverName: form.driverName.trim(),
        driverPhone: form.driverPhone.trim(),
      });
      onClose();
    } catch (err) {
      setServerError(
        err.code === "VEHICLE_EXISTS" ? "A vehicle with this number is already registered." : err.message
      );
      setSaving(false);
    }
  }

  const fields = [
    ["vehicleNumber", "Vehicle number", "UP14AB1234"],
    ["driverName", "Driver name", ""],
    ["driverPhone", "Driver phone", "+919876543210"],
  ];

  return (
    <form onSubmit={handleSubmit} noValidate className="mb-6 rounded-2xl bg-white/95 p-5 shadow-md">
      <h2 className="mb-4 font-semibold text-slate-900">Add an ambulance</h2>
      {serverError && (
        <p role="alert" className="mb-4 rounded-xl bg-red-50 p-3 text-sm text-red-700">
          {serverError}
        </p>
      )}
      <div className="grid gap-4 sm:grid-cols-3">
        {fields.map(([field, label, placeholder]) => (
          <div key={field}>
            <label htmlFor={`add-${field}`} className="mb-1 block text-sm font-medium text-slate-700">
              {label}
            </label>
            <input
              id={`add-${field}`}
              value={form[field]}
              onChange={update(field)}
              placeholder={placeholder}
              className={inputClass}
            />
            {errors[field] && <p className="mt-1 text-xs text-red-600">{errors[field]}</p>}
          </div>
        ))}
      </div>
      <div className="mt-4 flex gap-3">
        <button
          type="submit"
          disabled={saving}
          className="rounded-xl bg-primary/70 px-5 py-2 text-sm font-medium text-white hover:bg-primary/80 disabled:opacity-60"
        >
          {saving ? "Adding…" : "Add ambulance"}
        </button>
        <button
          type="button"
          onClick={onClose}
          className="rounded-xl border border-slate-300 px-5 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}