import { useState } from "react";
import { Link, NavLink, useNavigate } from "react-router-dom";
import { HeartPulse, Menu, X, User, LogOut } from "lucide-react";
import { useAuth, ROLE_HOME } from "../context/AuthContext";

const NAV_LINKS = [
  { label: "Home", to: "/" },
  { label: "About", to: "/about" },
  { label: "Departments", to: "/departments" },
  { label: "Features", href: "/#features" },
  { label: "How It Works", href: "/about#how-it-works" },
];

const ROLE_LINK = {
  patient: { label: "My Queue", to: "/queue" },
  doctor: { label: "Dashboard", to: "/doctor" },
  receptionist: { label: "Dashboard", to: "/staff" },
  admin: { label: "Dashboard", to: "/staff" },
};

const STAFF_ROLES = ["receptionist", "admin"];
const AMBULANCE_LINK = { label: "Ambulance Tracking", to: "/ambulance" };

const baseLink = "border-b-2 pb-1 text-sm font-medium transition-colors";
const activeLink = "border-primary/60 text-primary/70";
const idleLink = "border-transparent text-slate-600 hover:text-primary/70";

function NavItem({ link, onClick, mobile = false }) {
  if (link.href) {
    return (
      <a
        href={link.href}
        onClick={onClick}
        className={
          mobile
            ? "block rounded-lg px-3 py-2 text-slate-700 hover:bg-primary/5"
            : `${baseLink} ${idleLink}`
        }
      >
        {link.label}
      </a>
    );
  }

  return (
    <NavLink
      to={link.to}
      end={link.label === "Home" || link.to === "/"}
      onClick={onClick}
      className={({ isActive }) =>
        mobile
          ? `block rounded-lg px-3 py-2 ${
              isActive ? "bg-primary/5 text-primary/70" : "text-slate-700 hover:bg-primary/5"
            }`
          : `${baseLink} ${isActive ? activeLink : idleLink}`
      }
    >
      {link.label}
    </NavLink>
  );
}

function AuthActions({ onNavigate, mobile = false }) {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    signOut();
    onNavigate?.();
    navigate("/");
  }

  const wrapper = mobile ? "mt-3 flex gap-3" : "flex items-center gap-3";
  const fill = mobile ? "flex-1" : "";

  if (user) {
    return (
      <div className={wrapper}>
        <Link
          to={ROLE_HOME[user.role] ?? "/"}
          onClick={onNavigate}
          title={`${user.name} (${user.role})`}
          className={`${fill} inline-flex items-center justify-center gap-2 rounded-lg bg-primary/5 px-4 py-2 text-sm font-medium text-primary/80 transition-colors hover:bg-primary/10`}
        >
          <User className="h-4 w-4" />
          <span className="max-w-[9rem] truncate">{user.name.split(" ")[0]}</span>
        </Link>
        <button
          type="button"
          onClick={handleLogout}
          className={`${fill} inline-flex items-center justify-center gap-2 rounded-lg border border-primary/60 px-4 py-2 text-sm font-medium text-primary/70 transition-colors hover:bg-primary/5`}
        >
          <LogOut className="h-4 w-4" />
          Log out
        </button>
      </div>
    );
  }

  return (
    <div className={wrapper}>
      <Link
        to="/login"
        onClick={onNavigate}
        className={`${fill} rounded-lg border border-primary/60 px-5 py-2 text-center text-sm font-medium text-primary/70 transition-colors hover:bg-primary/5`}
      >
        Login
      </Link>
      <Link
        to="/login"
        onClick={onNavigate}
        className={`${fill} rounded-lg bg-primary/70 px-5 py-2 text-center text-sm font-medium text-white shadow-sm transition-colors hover:bg-primary/80`}
      >
        Get Started
      </Link>
    </div>
  );
}

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const { user } = useAuth();
  const homePath = user ? ROLE_HOME[user.role] ?? "/" : "/";
  const isStaff = STAFF_ROLES.includes(user?.role);
  const extra = user && ROLE_LINK[user.role];
  const links = NAV_LINKS.filter(
    (link) => !isStaff || !["Home", "About", "Features", "How It Works"].includes(link.label)
  ).map((link) =>
    link.label === "Home" ? { ...link, to: homePath } : link
  );
  if (isStaff) links.push(AMBULANCE_LINK);
  if (extra) links.push(extra);

  return (
    <header className="relative z-20">
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        {/* Logo */}
        <Link to={homePath} className="flex items-center gap-2">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/60 text-white">
            <HeartPulse className="h-5 w-5" />
          </span>
          <span className="text-lg font-semibold text-slate-800">Smart Hospital</span>
        </Link>

        {/* Desktop links */}
        <ul className="hidden items-center gap-8 md:flex">
          {links.map((link) => (
            <li key={link.label}>
              <NavItem link={link} />
            </li>
          ))}
        </ul>

        {/* Desktop actions */}
        <div className="hidden md:block">
          <AuthActions />
        </div>

        {/* Mobile toggle */}
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          className="rounded-lg p-2 text-slate-700 hover:bg-white/60 md:hidden"
          aria-label={open ? "Close menu" : "Open menu"}
          aria-expanded={open}
        >
          {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </nav>

      {/* Mobile menu */}
      {open && (
        <div className="mx-6 rounded-2xl bg-white p-4 shadow-lg md:hidden">
          <ul className="flex flex-col gap-1">
            {links.map((link) => (
              <li key={link.label}>
                <NavItem link={link} mobile onClick={() => setOpen(false)} />
              </li>
            ))}
          </ul>
          <AuthActions mobile onNavigate={() => setOpen(false)} />
        </div>
      )}
    </header>
  );
}