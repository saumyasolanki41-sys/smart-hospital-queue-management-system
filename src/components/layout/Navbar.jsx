import { useState } from "react";
import { Link, NavLink } from "react-router-dom";
import { HeartPulse, Menu, X } from "lucide-react";
import { useAuth } from "../context/AuthContext";

const NAV_LINKS = [
  { label: "Home", to: "/" },
  { label: "About", href: "/#about" },
  { label: "Departments", to: "/departments" },
  { label: "Features", href: "/#features" },
  { label: "How It Works", href: "/#how-it-works" },
];

const baseLink = "border-b-2 pb-1 text-sm font-medium transition-colors";
const activeLink = "border-primary/60 text-primary/70";
const idleLink = "border-transparent text-slate-600 hover:text-primary/70";

function NavItem({ link, onClick, mobile = false }) {
  if (link.href) {
    return (
      <Link
        to={link.href}
        onClick={onClick}
        className={
          mobile
            ? "block rounded-lg px-3 py-2 text-slate-700 hover:bg-primary/5"
            : `${baseLink} ${idleLink}`
        }
      >
        {link.label}
      </Link>
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
  const wrapper = mobile ? "mt-3 flex gap-3" : "flex items-center gap-3";
  const fill = mobile ? "flex-1" : "";

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
        to="/Register"
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

  if (user) return null;

  return (
    <header className="relative z-20">
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        {/* Logo */}
        <Link to="/" className="flex items-center gap-2">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/60 text-white">
            <HeartPulse className="h-5 w-5" />
          </span>
          <span className="text-lg font-semibold text-slate-800">Smart Hospital</span>
        </Link>

        {/* Desktop links */}
        <ul className="hidden items-center gap-8 md:flex">
          {NAV_LINKS.map((link) => (
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
            {NAV_LINKS.map((link) => (
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