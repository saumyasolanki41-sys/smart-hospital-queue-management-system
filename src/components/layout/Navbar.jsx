// src/components/layout/Navbar.jsx
import { useState } from "react";
import { Link, NavLink, useNavigate } from "react-router-dom";
import { HeartPulse, Menu, X, User, LogOut } from "lucide-react";
import { useAuth, ROLE_HOME } from "../context/AuthContext";

// Page links use "to" (real routes). Section links use "href" (anchors).
const NAV_LINKS = [
  { label: "Home", to: "/" },
  { label: "About", to: "/about" },
  { label: "Departments", to: "/departments" },
  { label: "Features", href: "/#features" },
  { label: "How It Works", href: "/about#how-it-works" },
];

const baseLink = "border-b-2 pb-1 text-sm font-medium transition-colors";
const activeLink = "border-teal-600 text-teal-700";
const idleLink = "border-transparent text-slate-600 hover:text-teal-700";

function NavItem({ link, onClick, mobile = false }) {
  if (link.href) {
    return (
      <a
        href={link.href}
        onClick={onClick}
        className={
          mobile
            ? "block rounded-lg px-3 py-2 text-slate-700 hover:bg-teal-50"
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
      end={link.to === "/"}
      onClick={onClick}
      className={({ isActive }) =>
        mobile
          ? `block rounded-lg px-3 py-2 ${
              isActive ? "bg-teal-50 text-teal-700" : "text-slate-700 hover:bg-teal-50"
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
          className={`${fill} inline-flex items-center justify-center gap-2 rounded-lg bg-teal-50 px-4 py-2 text-sm font-medium text-teal-800 transition-colors hover:bg-teal-100`}
        >
          <User className="h-4 w-4" />
          <span className="max-w-[9rem] truncate">{user.name.split(" ")[0]}</span>
        </Link>
        <button
          type="button"
          onClick={handleLogout}
          className={`${fill} inline-flex items-center justify-center gap-2 rounded-lg border border-teal-600 px-4 py-2 text-sm font-medium text-teal-700 transition-colors hover:bg-teal-50`}
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
        className={`${fill} rounded-lg border border-teal-600 px-5 py-2 text-center text-sm font-medium text-teal-700 transition-colors hover:bg-teal-50`}
      >
        Login
      </Link>
      <Link
        to="/login"
        onClick={onNavigate}
        className={`${fill} rounded-lg bg-teal-700 px-5 py-2 text-center text-sm font-medium text-white shadow-sm transition-colors hover:bg-teal-800`}
      >
        Get Started
      </Link>
    </div>
  );
}

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const { user } = useAuth();
  const links =
    user?.role === "patient" ? [...NAV_LINKS, { label: "My Queue", to: "/queue" }] : NAV_LINKS;

  return (
    <header className="relative z-20">
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        {/* Logo */}
        <Link to="/" className="flex items-center gap-2">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-teal-600 text-white">
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