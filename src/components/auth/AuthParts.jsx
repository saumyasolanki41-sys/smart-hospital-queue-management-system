import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { HeartPulse, Eye, EyeOff, Loader, Info, User, Stethoscope, ClipboardList } from "lucide-react";
import DashboardBackground from "../layout/DashboardBackground";
import { ROLE_OPTIONS } from "../../api/auth";

const inputClass = (error) =>
  `w-full rounded-2xl border bg-white/90 backdrop-blur-sm px-4 py-2.5 text-sm text-slate-900 outline-none transition-all shadow-2xs ${
    error
      ? "border-red-400 focus:border-red-500 focus:ring-4 focus:ring-red-500/10"
      : "border-slate-200/90 focus:border-[#197092] focus:ring-4 focus:ring-cyan-500/15"
  }`;

const labelClass = "mb-1.5 block text-xs font-semibold uppercase tracking-wider text-slate-600";

export function AuthShell({ title, subtitle, children, footer }) {
  return (
    <DashboardBackground>
      <div className="flex min-h-screen flex-col items-center justify-center px-6 py-12">
        <Link to="/" className="mb-6 flex items-center gap-2.5 group">
          <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#197092] text-white shadow-md shadow-cyan-950/20 group-hover:bg-[#145d7a] transition-all">
            <HeartPulse className="h-5 w-5" />
          </span>
          <span className="text-xl font-bold text-slate-900 tracking-tight">Smart Hospital</span>
        </Link>

        <div className="w-full max-w-md rounded-3xl bg-white/95 backdrop-blur-xl p-8 shadow-2xl shadow-cyan-950/10 border border-white/80">
          <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-slate-600">{subtitle}</p>}
          <div className="mt-6">{children}</div>
        </div>

        {footer && <div className="mt-6 text-sm text-slate-600">{footer}</div>}
      </div>
    </DashboardBackground>
  );
}

export function TextField({ label, error, id, className = "", ...props }) {
  return (
    <div>
      <label htmlFor={id} className={labelClass}>
        {label}
      </label>
      <input id={id} aria-invalid={!!error} {...props} className={`${inputClass(error)} ${className}`} />
      {error && <p className="mt-1.5 text-xs font-medium text-red-600">{error}</p>}
    </div>
  );
}

export function PasswordField({ label, error, id, ...props }) {
  const [show, setShow] = useState(false);
  return (
    <div>
      <label htmlFor={id} className={labelClass}>
        {label}
      </label>
      <div className="relative">
        <input
          id={id}
          type={show ? "text" : "password"}
          aria-invalid={!!error}
          {...props}
          className={`${inputClass(error)} pr-11`}
        />
        <button
          type="button"
          onClick={() => setShow((v) => !v)}
          aria-label={show ? "Hide password" : "Show password"}
          className="absolute inset-y-0 right-3 flex items-center text-slate-400 hover:text-slate-600 transition-colors"
        >
          {show ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
        </button>
      </div>
      {error && <p className="mt-1.5 text-xs font-medium text-red-600">{error}</p>}
    </div>
  );
}

export function Banner({ type = "error", children }) {
  const style =
    type === "error"
      ? "bg-red-50 text-red-700 border-red-200/80"
      : type === "success"
      ? "bg-emerald-50 text-emerald-800 border-emerald-200/80"
      : "bg-cyan-50/90 text-cyan-950 border-cyan-200/80";
  return (
    <div
      role={type === "error" ? "alert" : "status"}
      className={`flex items-start gap-2.5 rounded-2xl p-3.5 text-xs sm:text-sm border shadow-2xs ${style}`}
    >
      <Info className="mt-0.5 h-4 w-4 shrink-0" />
      <span className="leading-relaxed">{children}</span>
    </div>
  );
}

export function SubmitButton({ loading, children, ...props }) {
  return (
    <button
      type="submit"
      disabled={loading}
      {...props}
      className="flex w-full items-center justify-center gap-2 rounded-2xl bg-[#197092] hover:bg-[#145d7a] px-6 py-3 text-sm font-semibold text-white shadow-md shadow-cyan-950/15 transition-all duration-200 disabled:cursor-not-allowed disabled:opacity-60 active:scale-[0.99]"
    >
      {loading && <Loader className="h-4 w-4 animate-spin" />}
      {children}
    </button>
  );
}

const ROLE_ICONS = { patient: User, doctor: Stethoscope, staff: ClipboardList };

export function RoleSelector({ value, onChange }) {
  return (
    <div>
      <span className={labelClass}>I am a</span>
      <div
        role="radiogroup"
        aria-label="Account type"
        className="grid grid-cols-3 gap-1.5 rounded-2xl bg-cyan-50/80 border border-cyan-100 p-1.5"
      >
        {ROLE_OPTIONS.map(({ value: optionValue, label }) => {
          const Icon = ROLE_ICONS[optionValue];
          const active = optionValue === value;
          return (
            <button
              key={optionValue}
              type="button"
              role="radio"
              aria-checked={active}
              onClick={() => onChange(optionValue)}
              className={`flex items-center justify-center gap-1.5 rounded-xl px-2.5 py-2 text-xs font-semibold transition-all duration-200 ${
                active
                  ? "bg-gradient-to-r from-[#197092] to-[#0c4764] text-white shadow-sm shadow-cyan-950/20"
                  : "text-slate-600 hover:text-slate-900 hover:bg-white/60"
              }`}
            >
              <Icon className="h-3.5 w-3.5" />
              {label}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export function useCooldown() {
  const [left, setLeft] = useState(0);

  useEffect(() => {
    if (left <= 0) return;
    const timer = setTimeout(() => setLeft((s) => s - 1), 1000);
    return () => clearTimeout(timer);
  }, [left]);

  const start = useCallback((seconds = 60) => setLeft(seconds), []);
  return [left, start];
}
