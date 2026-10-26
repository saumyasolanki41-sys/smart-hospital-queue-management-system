import { useState } from "react";
import { Link, NavLink, useNavigate } from "react-router-dom";
import {
  HeartPulse,
  LayoutDashboard,
  Stethoscope,
  Ticket,
  Info,
  Ambulance,
  LogOut,
  Menu,
  X,
  User,
} from "lucide-react";
import { useAuth, ROLE_HOME } from "../context/AuthContext";
import { useOwnDoctorId } from "../../hooks/useOwnDoctorId";

const STAFF_NAV = [
  { label: "Dashboard", to: "/staff", icon: LayoutDashboard },
  { label: "Departments", to: "/departments", icon: Stethoscope },
  { label: "Ambulance Tracking", to: "/ambulance", icon: Ambulance },
];

const NAV_BY_ROLE = {
  patient: [
    { label: "Home", to: "/home", icon: LayoutDashboard },
    { label: "Departments", to: "/departments", icon: Stethoscope },
    { label: "My Queue", to: "/queue", icon: Ticket },
    { label: "Ambulance", to: "/request-ambulance", icon: Ambulance },
    { label: "About", to: "/about", icon: Info },
  ],
  doctor: [
    { label: "Dashboard", to: "/doctor", icon: LayoutDashboard },
    { label: "Departments", to: "/departments", icon: Stethoscope },
  ],
  receptionist: STAFF_NAV,
  admin: STAFF_NAV,
};

const ROLE_LABEL = {
  patient: "Patient",
  doctor: "Doctor",
  receptionist: "Receptionist",
  admin: "Admin",
};

function Logo({ onClick, to }) {
  return (
    <Link to={to} onClick={onClick} className="flex items-center gap-2">
      <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/60 text-white">
        <HeartPulse className="h-5 w-5" />
      </span>
      <span className="text-lg font-semibold text-slate-800">Smart Hospital</span>
    </Link>
  );
}

function Panel({ onNavigate, ownDoctorId }) {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const base = NAV_BY_ROLE[user.role] ?? [];

  const items = ownDoctorId
    ? [base[0], { label: "My profile", to: `/doctors/${ownDoctorId}`, icon: User }, ...base.slice(1)]
    : base;

  function handleLogout() {
    signOut();
    onNavigate?.();
    navigate("/");
  }

  return (
    <div className="flex h-full flex-col rounded-3xl bg-primary/90 p-5 text-white shadow-xl">
      <Link to={ROLE_HOME[user.role] ?? "/"} onClick={onNavigate} className="mb-8 mt-2 block px-2 text-center">
        <span className="flex items-center justify-center gap-2 text-lg font-semibold">
          <HeartPulse className="h-5 w-5" />
          Smart Hospital
        </span>
        <span className="mt-1 block text-xs text-white/70">Queue Management System</span>
      </Link>

      <nav aria-label="Main" className="flex-1 space-y-1.5 overflow-y-auto">
        {items.map(({ label, to, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            onClick={onNavigate}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition-colors ${
                isActive ? "bg-white/20 text-white" : "text-white/80 hover:bg-white/10 hover:text-white"
              }`
            }
          >
            <Icon className="h-5 w-5 shrink-0" />
            {label}
          </NavLink>
        ))}
      </nav>

      <div className="mt-6 border-t border-white/20 pt-4">
        <div className="flex items-center gap-3 px-1">
          <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-white/20">
            <User className="h-5 w-5" />
          </span>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold">{user.name}</p>
            <p className="text-xs text-white/70">{ROLE_LABEL[user.role] ?? user.role}</p>
          </div>
        </div>
        <button
          type="button"
          onClick={handleLogout}
          className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl border border-white/30 px-4 py-2 text-sm font-medium transition-colors hover:bg-white/10"
        >
          <LogOut className="h-4 w-4" />
          Log out
        </button>
      </div>
    </div>
  );
}

export default function Sidebar() {
  const { user } = useAuth();
  const { doctorId: ownDoctorId } = useOwnDoctorId(); 
  const [open, setOpen] = useState(false);

  return (
    <>
      {/* Mobile top bar */}
      <div className="flex items-center justify-between px-6 py-4 lg:hidden">
        <Logo to={ROLE_HOME[user.role] ?? "/"} />
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="rounded-lg p-2 text-slate-700 hover:bg-white/60"
          aria-label="Open menu"
          aria-expanded={open}
        >
          <Menu className="h-6 w-6" />
        </button>
      </div>

      {/* Desktop sidebar */}
      <aside className="hidden w-72 shrink-0 self-start p-4 lg:sticky lg:top-0 lg:block lg:h-screen">
        <Panel ownDoctorId={ownDoctorId} />
      </aside>

      {/* Mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <button
            type="button"
            aria-label="Close menu"
            onClick={() => setOpen(false)}
            className="absolute inset-0 bg-black/40"
          />
          <div className="absolute inset-y-0 left-0 w-72 max-w-[85%] p-4">
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Close menu"
              className="absolute right-6 top-6 z-10 rounded-lg p-1 text-white/80 hover:bg-white/10"
            >
              <X className="h-5 w-5" />
            </button>
            <Panel onNavigate={() => setOpen(false)} ownDoctorId={ownDoctorId} />
          </div>
        </div>
      )}
    </>
  );
}