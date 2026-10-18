// src/components/auth/AuthParts.jsx — shared UI for the Login and Register pages.
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { HeartPulse, Eye, EyeOff, Loader, Info, User, Stethoscope, ClipboardList } from "lucide-react";
import { ROLE_OPTIONS } from "../../api/auth";

const inputClass = (error) =>
  `w-full rounded-xl border bg-white px-4 py-2.5 text-slate-900 outline-none transition focus:ring-2 focus:ring-teal-500/40 ${
    error ? "border-red-400" : "border-slate-200 focus:border-teal-600"
  }`;

const labelClass = "mb-1.5 block text-sm font-medium text-slate-700";

export function AuthShell({ title, subtitle, children, footer }) {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-br from-sky-50 via-cyan-50 to-white px-6 py-10">
      <Link to="/" className="mb-6 flex items-center gap-2">
        <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-teal-600 text-white">
          <HeartPulse className="h-5 w-5" />
        </span>
        <span className="text-lg font-semibold text-slate-800">Smart Hospital</span>
      </Link>

      <div className="w-full max-w-md rounded-3xl bg-white/95 p-8 shadow-xl">
        <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-slate-600">{subtitle}</p>}
        <div className="mt-6">{children}</div>
      </div>

      {footer && <p className="mt-6 text-sm text-slate-600">{footer}</p>}
    </div>
  );
}

export function TextField({ label, error, id, className = "", ...props }) {
  return (
    <div>
      <label htmlFor={id} className={labelClass}>
        {label}
      </label>
      <input id={id} aria-invalid={!!error} {...props} className={`${inputClass(error)} ${className}`} />
      {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
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
          className="absolute inset-y-0 right-3 text-slate-500 hover:text-slate-700"
        >
          {show ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
        </button>
      </div>
      {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
    </div>
  );
}

export function Banner({ type = "error", children }) {
  const style =
    type === "error"
      ? "bg-red-50 text-red-700"
      : type === "success"
      ? "bg-green-50 text-green-800"
      : "bg-sky-50 text-sky-800";
  return (
    <div role={type === "error" ? "alert" : "status"} className={`flex items-start gap-2 rounded-xl p-3 text-sm ${style}`}>
      <Info className="mt-0.5 h-4 w-4 shrink-0" />
      <span>{children}</span>
    </div>
  );
}

export function SubmitButton({ loading, children, ...props }) {
  return (
    <button
      type="submit"
      disabled={loading}
      {...props}
      className="flex w-full items-center justify-center gap-2 rounded-xl bg-teal-700 px-6 py-3 font-medium text-white shadow-md transition-colors hover:bg-teal-800 disabled:cursor-not-allowed disabled:opacity-60"
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
        className="grid grid-cols-3 gap-1 rounded-2xl bg-slate-100 p-1"
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
              className={`flex items-center justify-center gap-1.5 rounded-xl px-2 py-2 text-sm font-medium transition ${
                active ? "bg-white text-teal-700 shadow" : "text-slate-600 hover:text-slate-800"
              }`}
            >
              <Icon className="h-4 w-4" />
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