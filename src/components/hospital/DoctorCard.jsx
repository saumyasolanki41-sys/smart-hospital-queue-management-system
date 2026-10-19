// src/components/hospital/DoctorCard.jsx
import { Briefcase, Clock, Wallet } from "lucide-react";

const inr = new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
  maximumFractionDigits: 0,
});

// The API has no photo field, so show initials instead ("Dr Asha Rao" -> "AR").
function initials(name) {
  const parts = name.replace(/^dr\.?\s+/i, "").trim().split(/\s+/);
  return ((parts[0]?.[0] ?? "") + (parts[1]?.[0] ?? "")).toUpperCase() || "D";
}

export default function DoctorCard({ doctor, showJoin = true, onJoin, joining = false, busy = false }) {
  const {
    name,
    specialization,
    department,
    experienceYears,
    consultationFee,
    isAvailable,
    averageConsultationMinutes, // may be missing on older records
  } = doctor;

  return (
    <article className="flex flex-col rounded-3xl bg-white/90 p-5 shadow-md">
      <div className="flex items-start gap-4">
        <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-sky-100 font-semibold text-teal-800">
          {initials(name)}
        </span>
        <div className="min-w-0 flex-1">
          <h3 className="truncate font-semibold text-slate-900">{name}</h3>
          <p className="truncate text-sm text-slate-600">{specialization}</p>
          {department?.name && <p className="text-xs text-slate-400">{department.name}</p>}
        </div>
        <span
          className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-medium ${
            isAvailable ? "bg-green-100 text-green-800" : "bg-slate-100 text-slate-600"
          }`}
        >
          {isAvailable ? "Available" : "Unavailable"}
        </span>
      </div>

      <ul className="mt-4 space-y-2 text-sm text-slate-600">
        <li className="flex items-center gap-2">
          <Briefcase className="h-4 w-4 text-teal-600" />
          {experienceYears} {experienceYears === 1 ? "year" : "years"} of experience
        </li>
        <li className="flex items-center gap-2">
          <Wallet className="h-4 w-4 text-teal-600" />
          {consultationFee > 0 ? `${inr.format(consultationFee)} consultation fee` : "Fee not listed"}
        </li>
        {averageConsultationMinutes && (
          <li className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-teal-600" />
            About {averageConsultationMinutes} min per patient
          </li>
        )}
      </ul>

      {showJoin && (
        <button
          type="button"
          disabled={!isAvailable || busy}
          onClick={() => onJoin?.(doctor)}
          className="mt-5 w-full rounded-xl bg-teal-700 px-5 py-2.5 text-sm font-medium text-white shadow-sm transition-colors hover:bg-teal-800 disabled:cursor-not-allowed disabled:bg-slate-200 disabled:text-slate-500 disabled:shadow-none"
        >
          {joining ? "Joining…" : isAvailable ? "Join Queue" : "Not taking patients"}
        </button>
      )}
    </article>
  );
}