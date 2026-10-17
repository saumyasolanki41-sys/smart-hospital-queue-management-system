import { useState } from "react";
import { Link, NavLink } from "react-router-dom";
import { HeartPulse, Menu, X } from "lucide-react";

const NAV_LINKS = [
  { label: "Home", to: "/" },
  { label: "About", href: "/#about" },
  { label: "Features", href: "/#features" },
  { label: "How It Works", href: "/#how-it-works" },
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

export default function Navbar() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky relative z-20">
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
          {NAV_LINKS.map((link) => (
            <li key={link.label}>
              <NavItem link={link} />
            </li>
          ))}
        </ul>

        {/* Desktop buttons */}
        <div className="hidden items-center gap-3 md:flex">
          <Link
            to="/login"
            className="rounded-lg border border-teal-600 px-5 py-2 text-sm font-medium text-teal-700 transition-colors hover:bg-teal-50"
          >
            Login
          </Link>
          <Link
            to="/login"
            className="rounded-lg bg-teal-700 px-5 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-teal-800"
          >
            Get Started
          </Link>
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
          <div className="mt-3 flex gap-3">
            <Link
              to="/login"
              onClick={() => setOpen(false)}
              className="flex-1 rounded-lg border border-teal-600 py-2 text-center text-sm font-medium text-teal-700"
            >
              Login
            </Link>
            <Link
              to="/login"
              onClick={() => setOpen(false)}
              className="flex-1 rounded-lg bg-teal-700 py-2 text-center text-sm font-medium text-white"
            >
              Get Started
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}