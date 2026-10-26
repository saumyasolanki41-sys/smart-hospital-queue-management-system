import { useCallback, useState } from "react";
import { LocateFixed, MapPin } from "lucide-react";
import AmbulanceMap from "./AmbulanceMap";

const EMPTY = []; // a stable value, so the map doesn't redraw while typing
const round6 = (n) => Math.round(n * 1e6) / 1e6;

const inputClass =
  "w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/40";

function validate({ address, phone, point }) {
  const errors = {};
  if (address.length < 5 || address.length > 300) errors.address = "Enter the pickup address (5–300 characters).";
  if (!/^\+?[1-9]\d{9,14}$/.test(phone)) {
    errors.phone = "Enter 10–15 digits, optionally starting with +, and not starting with 0.";
  }
  if (!point) errors.point = "Tap the map or use your current location to pin where the ambulance should come.";
  return errors;
}

function errorText(err) {
  if (err.code === "ACTIVE_REQUEST_EXISTS") return "You already have an active ambulance request.";
  if (err.code === "RATE_LIMITED") return "Too many requests in a short time. Please wait a few minutes.";
  return err.message;
}

export default function AmbulanceRequestForm({ onSubmit }) {
  const [form, setForm] = useState({ address: "", phone: "" });
  const [point, setPoint] = useState(null); // { lat, lng }
  const [focus, setFocus] = useState(null);
  const [locating, setLocating] = useState(false);
  const [geoError, setGeoError] = useState("");
  const [errors, setErrors] = useState({});
  const [serverError, setServerError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const update = (field) => (e) => setForm((f) => ({ ...f, [field]: e.target.value }));

  const handlePick = useCallback((lat, lng) => {
    setPoint({ lat: round6(lat), lng: round6(lng) });
    setGeoError("");
  }, []);

  function locateMe() {
    if (!navigator.geolocation) {
      setGeoError("Your browser can't share your location. Tap the map to place the pin instead.");
      return;
    }
    setLocating(true);
    setGeoError("");
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const here = { lat: round6(pos.coords.latitude), lng: round6(pos.coords.longitude) };
        setPoint(here);
        setFocus({ ...here, key: Date.now() });
        setLocating(false);
      },
      (err) => {
        setLocating(false);
        setGeoError(
          err.code === 1
            ? "Location permission was denied. You can tap the map to place the pin instead."
            : "We couldn't get your location. Tap the map to place the pin instead."
        );
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    );
  }

  async function handleSubmit(e) {
    e.preventDefault();
    const address = form.address.replace(/\s+/g, " ").trim(); 
    const phone = form.phone.replace(/[\s()-]/g, ""); 

    const found = validate({ address, phone, point });
    setErrors(found);
    if (Object.keys(found).length > 0) return;

    setSubmitting(true);
    setServerError("");
    try {
      await onSubmit({ pickupAddress: address, latitude: point.lat, longitude: point.lng, contactPhone: phone });
      
    } catch (err) {
      setServerError(errorText(err));
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate className="space-y-5 rounded-3xl bg-white/95 p-6 shadow-xl sm:p-8">
      <h2 className="text-xl font-semibold text-slate-900">Request an ambulance</h2>

      {serverError && (
        <p role="alert" className="rounded-xl bg-red-50 p-3 text-sm text-red-700">
          {serverError}
        </p>
      )}

      <div>
        <label htmlFor="amb-address" className="mb-1.5 block text-sm font-medium text-slate-700">
          Pickup address
        </label>
        <textarea
          id="amb-address"
          rows={3}
          maxLength={300}
          value={form.address}
          onChange={update("address")}
          placeholder="House or building, street, landmark, city"
          className={inputClass}
        />
        {errors.address && <p className="mt-1 text-xs text-red-600">{errors.address}</p>}
      </div>

      <div>
        <label htmlFor="amb-phone" className="mb-1.5 block text-sm font-medium text-slate-700">
          Contact phone
        </label>
        <input
          id="amb-phone"
          type="tel"
          autoComplete="tel"
          value={form.phone}
          onChange={update("phone")}
          placeholder="+919876543210"
          className={inputClass}
        />
        <p className="mt-1 text-xs text-slate-500">A number staff can call to reach you or someone at the pickup.</p>
        {errors.phone && <p className="mt-1 text-xs text-red-600">{errors.phone}</p>}
      </div>

      <div>
        <p className="mb-1.5 text-sm font-medium text-slate-700">Pin the pickup location</p>
        <div className="mb-3 flex flex-wrap items-center gap-3">
          <button
            type="button"
            onClick={locateMe}
            disabled={locating}
            className="inline-flex items-center gap-2 rounded-xl border border-primary/60 px-4 py-2 text-sm font-medium text-primary/70 hover:bg-primary/5 disabled:opacity-60"
          >
            <LocateFixed className="h-4 w-4" />
            {locating ? "Finding you…" : "Use my current location"}
          </button>
          {point && (
            <>
              <span className="inline-flex items-center gap-1 text-sm text-slate-600">
                <MapPin className="h-4 w-4" />
                {point.lat.toFixed(5)}, {point.lng.toFixed(5)}
              </span>
              <button
                type="button"
                onClick={() => setPoint(null)}
                className="text-sm font-medium text-slate-500 hover:underline"
              >
                Clear
              </button>
            </>
          )}
        </div>
        {geoError && <p className="mb-3 rounded-xl bg-yellow-50 p-3 text-sm text-yellow-900">{geoError}</p>}

        <AmbulanceMap
          ambulances={EMPTY}
          requests={EMPTY}
          focus={focus}
          pickMode
          onPick={handlePick}
          pickedPoint={point}
          className="h-72"
        />
        <p className="mt-2 text-xs text-slate-500">Tap the map to place or move the pin. Zoom in for a precise spot.</p>
        {errors.point && <p className="mt-1 text-xs text-red-600">{errors.point}</p>}
      </div>

      <div>
        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-xl bg-primary/70 px-6 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto"
        >
          {submitting ? "Sending…" : "Send ambulance request"}
        </button>
        <p className="mt-3 text-xs text-slate-500">
          Hospital staff will see your request and assign an ambulance by hand. It does not call an ambulance
          automatically and can't promise a response time.
        </p>
      </div>
    </form>
  );
}