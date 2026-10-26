import { useState } from "react";
import { MapPin, Phone } from "lucide-react";
import { timeAgo } from "../../utils/time";

const STEPS = ["Request sent", "Ambulance assigned", "Completed"];
const STEP_INDEX = { pending: 0, assigned: 1, completed: 2 };

const humanize = (code) => String(code).replace(/_/g, " ");

function Progress({ status }) {
  const current = STEP_INDEX[status] ?? 0;
  return (
    <ol className="mt-5 flex items-start">
      {STEPS.map((label, i) => (
        <li key={label} className="flex flex-1 flex-col items-center text-center">
          <div className="flex w-full items-center">
            <span
              className={`h-0.5 flex-1 ${i === 0 ? "bg-transparent" : i <= current ? "bg-primary/60" : "bg-slate-200"}`}
            />
            <span
              className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-bold ${
                i <= current ? "bg-primary/70 text-white" : "bg-slate-200 text-slate-500"
              }`}
            >
              {i + 1}
            </span>
            <span
              className={`h-0.5 flex-1 ${
                i === STEPS.length - 1 ? "bg-transparent" : i < current ? "bg-primary/60" : "bg-slate-200"
              }`}
            />
          </div>
          <span className={`mt-2 text-xs ${i <= current ? "font-medium text-slate-800" : "text-slate-500"}`}>
            {label}
          </span>
        </li>
      ))}
    </ol>
  );
}

function EtaPanel({ eta, etaFailed }) {
  if (etaFailed) {
    return (
      <p className="mt-4 rounded-2xl bg-slate-50 p-4 text-sm text-slate-600">
        We couldn't check the arrival time just now. We'll try again shortly.
      </p>
    );
  }
  if (!eta) return <div className="mt-4 h-24 animate-pulse rounded-2xl bg-slate-100" />;

  if (eta.etaMinutes == null) {
    return (
      <div className="mt-4 rounded-2xl bg-slate-50 p-4 text-sm text-slate-700">
        <p className="font-medium">Arrival time isn't available yet</p>
        {eta.reason && <p className="mt-1 text-slate-500">Reason: {humanize(eta.reason)}</p>}
        <p className="mt-1 text-xs text-slate-500">
          An estimate needs a recent ambulance position from hospital staff.
        </p>
      </div>
    );
  }

  const minutes = eta.etaMinutes < 1 ? "Less than a minute" : `About ${Math.ceil(eta.etaMinutes)} min`;

  return (
    <div className="mt-4 rounded-2xl bg-primary/5 p-4">
      <p className="text-sm text-slate-600">Estimated arrival</p>
      <p className="text-3xl font-bold text-slate-900">{minutes}</p>
      {Number.isFinite(eta.distanceKm) && (
        <p className="text-sm text-slate-600">{eta.distanceKm.toFixed(1)} km by road</p>
      )}
      <p className="mt-2 text-xs text-slate-500">
        {eta.source === "ml"
          ? "Predicted by our model from the route, distance and weather."
          : "Based on normal driving time for the route, not a prediction."}{" "}
        It's an estimate, not a guarantee.
      </p>
      {eta.ambulanceLocationUpdatedAt && (
        <p className="mt-1 text-xs text-slate-500">
          Ambulance position entered by staff {timeAgo(eta.ambulanceLocationUpdatedAt)}.
        </p>
      )}
      {Array.isArray(eta.assumptions) && eta.assumptions.length > 0 && (
        <details className="mt-2 text-xs text-slate-500">
          <summary className="cursor-pointer">What does this estimate assume?</summary>
          <ul className="mt-1 list-disc pl-5">
            {eta.assumptions.map((a) => (
              <li key={a}>{humanize(a)}</li>
            ))}
          </ul>
        </details>
      )}
      {eta.attribution && <p className="mt-2 text-xs text-slate-400">{eta.attribution}</p>}
    </div>
  );
}

export default function RequestStatusCard({ request, eta, etaFailed, onCancel, cancelling }) {
  const [confirm, setConfirm] = useState(false);
  const pending = request.status === "pending";
  const vehicle = request.ambulance?.vehicleNumber;

  return (
    <article className="rounded-3xl bg-white/95 p-6 shadow-xl sm:p-8">
      <p className="text-sm text-slate-500">Your ambulance request</p>
      <h2 className="mt-1 text-xl font-semibold text-slate-900">
        {pending
          ? "Waiting for staff to assign an ambulance"
          : `Ambulance ${vehicle ?? ""} has been assigned`.replace("  ", " ")}
      </h2>

      <Progress status={request.status} />

      {!pending && <EtaPanel eta={eta} etaFailed={etaFailed} />}

      <dl className="mt-5 space-y-2 text-sm text-slate-600">
        <div className="flex items-start gap-2">
          <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-primary/70" />
          <dd>{request.pickupAddress}</dd>
        </div>
        <div className="flex items-center gap-2">
          <Phone className="h-4 w-4 shrink-0 text-primary/70" />
          <dd>{request.contactPhone}</dd>
        </div>
        <p className="text-xs text-slate-500">Requested {timeAgo(request.createdAt)}</p>
      </dl>

      <div className="mt-5 border-t border-slate-100 pt-4">
        {pending ? (
          confirm ? (
            <div className="flex flex-wrap items-center gap-3 text-sm">
              <span className="text-slate-700">Cancel this request?</span>
              <button
                type="button"
                disabled={cancelling}
                onClick={async () => {
                  await onCancel();
                  setConfirm(false);
                }}
                className="rounded-lg bg-red-600 px-4 py-1.5 font-medium text-white hover:bg-red-700 disabled:opacity-60"
              >
                {cancelling ? "Cancelling…" : "Yes, cancel"}
              </button>
              <button
                type="button"
                onClick={() => setConfirm(false)}
                className="rounded-lg border border-slate-300 px-4 py-1.5 font-medium text-slate-700 hover:bg-slate-50"
              >
                Keep request
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setConfirm(true)}
              className="rounded-lg border border-red-300 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-50"
            >
              Cancel request
            </button>
          )
        ) : (
          <p className="text-sm text-slate-500">
            Once an ambulance is assigned, only hospital staff can cancel. Please contact them if you need to.
          </p>
        )}
      </div>
    </article>
  );
}