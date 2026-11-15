import { Link } from "react-router-dom";
import { Briefcase, Clock, Wallet, PauseCircle } from "lucide-react";

const inr = new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
  maximumFractionDigits: 0,
});

function initials(name) {
  const parts = name.replace(/^dr\.?\s+/i, "").trim().split(/\s+/);
  return ((parts[0]?.[0] ?? "") + (parts[1]?.[0] ?? "")).toUpperCase() || "D";
}

export default function DoctorCard({
  doctor,
  showJoin = true,
  onJoin,
  joining = false,
  busy = false,
  link = true,
}) {
  const {
    name,
    specialization,
    department,
    experienceYears,
    consultationFee,
    isAvailable,
    averageConsultationMinutes,
    queuePaused,
    queuePauseReason,
  } = doctor;

  const pauseLabel =
    queuePauseReason === "temporary_delay" ? "Temporary delay" : "On break";

  return (
    <article className="flex flex-col rounded-3xl bg-white/90 backdrop-blur-md p-5 shadow-md shadow-cyan-950/5 border border-white/80 hover:shadow-xl hover:border-cyan-100 transition-all duration-200">
      <div className="flex items-start gap-4">
        <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-cyan-50 font-semibold text-[#197092] border border-cyan-100/80 shadow-sm">
          {initials(name)}
        </span>
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-semibold text-slate-900">
            {link ? (
              <Link to={`/doctors/${doctor._id}`} className="hover:text-[#197092] transition-colors">
                {name}
              </Link>
            ) : (
              name
            )}
          </h3>
          <p className="truncate text-sm text-slate-600">{specialization}</p>
          {department?.name && <p className="text-xs text-slate-400">{department.name}</p>}
        </div>
        <div className="flex flex-col items-end gap-1 shrink-0">
          <span
            className={`rounded-full px-2.5 py-1 text-xs font-medium border ${
              isAvailable
                ? "bg-emerald-50 text-emerald-700 border-emerald-200/60"
                : "bg-slate-100 text-slate-600 border-slate-200/60"
            }`}
          >
            {isAvailable ? "Available" : "Unavailable"}
          </span>
          {queuePaused && (
            <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-semibold text-amber-800 border border-amber-200/70">
              <PauseCircle className="h-3 w-3 text-amber-600" />
              Paused
            </span>
          )}
        </div>
      </div>

      {queuePaused && (
        <div className="mt-3 flex items-center gap-1.5 rounded-2xl bg-amber-50/90 border border-amber-200/70 px-3 py-1.5 text-xs text-amber-900 font-medium">
          <PauseCircle className="h-3.5 w-3.5 shrink-0 text-amber-600" />
          <span>Queue paused ({pauseLabel}) · Booking is still open</span>
        </div>
      )}

      <ul className="mt-4 space-y-2 text-sm text-slate-600">
        <li className="flex items-center gap-2">
          <Briefcase className="h-4 w-4 text-[#197092]" />
          {experienceYears} {experienceYears === 1 ? "year" : "years"} of experience
        </li>
        <li className="flex items-center gap-2">
          <Wallet className="h-4 w-4 text-[#197092]" />
          {consultationFee > 0 ? `${inr.format(consultationFee)} consultation fee` : "Fee not listed"}
        </li>
        {averageConsultationMinutes && (
          <li className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-[#197092]" />
            About {averageConsultationMinutes} min per patient
          </li>
        )}
      </ul>

      {link && (
        <Link
          to={`/doctors/${doctor._id}`}
          className="mt-3 text-sm font-medium text-[#197092] hover:text-[#0c4764] hover:underline"
        >
          View profile →
        </Link>
      )}

      {showJoin && (
        <button
          type="button"
          disabled={!isAvailable || busy}
          onClick={() => onJoin?.(doctor)}
          className="mt-5 w-full rounded-2xl bg-[#197092] hover:bg-[#145d7a] px-5 py-2.5 text-sm font-medium text-white shadow-sm shadow-cyan-950/10 transition-colors disabled:cursor-not-allowed disabled:bg-slate-200 disabled:text-slate-500 disabled:shadow-none"
        >
          {joining
            ? "Joining…"
            : isAvailable
            ? queuePaused
              ? "Join Queue (Paused)"
              : "Join Queue"
            : "Not taking patients"}
        </button>
      )}
    </article>
  );
}
