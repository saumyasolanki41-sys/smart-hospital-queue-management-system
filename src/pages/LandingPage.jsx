import { useState } from "react";
import { Link } from "react-router-dom";
import {
  HeartPulse,
  Clock,
  Play,
  Menu,
  X,
  Ticket,
  Users,
  Bell,
  Stethoscope,
  ClipboardList,
  ShieldCheck,
} from "lucide-react";

const HERO_IMAGE = "/hero.jpg";

const NAV_LINKS = [
  { label: "Home", href: "#home" },
  { label: "About", href: "#about" },
  { label: "Features", href: "#features" },
  { label: "How It Works", href: "#how-it-works" },
];

const FEATURES = [
  { icon: Ticket, title: "Digital Token Booking", text: "Skip the long queues." },
  { icon: Users, title: "Live Queue Tracking", text: "Know your wait time." },
  { icon: Bell, title: "Instant Notifications", text: "Get timely updates." },
  { icon: Stethoscope, title: "Doctor & Department", text: "Choose with ease." },
  { icon: ClipboardList, title: "Efficient Management", text: "For better operations." },
  { icon: ShieldCheck, title: "Secure & Reliable", text: "Your data is safe." },
];

function Navbar() {
  const [open, setOpen] = useState(false);

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
          {NAV_LINKS.map((link, i) => (
            <li key={link.label}>
              <a
                href={link.href}
                className={`border-b-2 pb-1 text-sm font-medium transition-colors ${
                  i === 0
                    ? "border-teal-600 text-teal-700"
                    : "border-transparent text-slate-600 hover:text-teal-700"
                }`}
              >
                {link.label}
              </a>
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
                <a
                  href={link.href}
                  onClick={() => setOpen(false)}
                  className="block rounded-lg px-3 py-2 text-slate-700 hover:bg-teal-50"
                >
                  {link.label}
                </a>
              </li>
            ))}
          </ul>
          <div className="mt-3 flex gap-3">
            <Link
              to="/login"
              className="flex-1 rounded-lg border border-teal-600 py-2 text-center text-sm font-medium text-teal-700"
            >
              Login
            </Link>
            <Link
              to="/login"
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

function TokenCard() {
  return (
    <div className="absolute -left-4 bottom-8 w-52 rounded-2xl bg-white/95 p-4 shadow-xl backdrop-blur sm:-left-10">
      <div className="flex items-center gap-3">
        <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-sky-100 text-teal-700">
          <HeartPulse className="h-5 w-5" />
        </span>
        <div>
          <p className="text-xs text-slate-500">Your Token No.</p>
          <p className="text-lg font-bold text-slate-800">A-023</p>
        </div>
      </div>
      <div className="mt-3 flex items-center gap-3 border-t border-slate-100 pt-3">
        <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-sky-100 text-teal-700">
          <Clock className="h-5 w-5" />
        </span>
        <div>
          <p className="text-xs text-slate-500">Waiting Time</p>
          <p className="text-lg font-bold text-slate-800">15 mins</p>
        </div>
      </div>
    </div>
  );
}

function Hero() {
  return (
    <section
      id="home"
      className="mx-auto grid max-w-6xl items-center gap-10 px-6 pb-16 pt-8 md:grid-cols-2 md:pt-12"
    >
      {/* Left: text */}
      <div>
        <p className="mb-3 text-base font-medium text-teal-700">
          Smarter Queues. Better Care.
        </p>
        <h1 className="text-4xl font-bold leading-tight text-slate-900 sm:text-5xl">
          Smart Hospital
          <br />
          <span className="text-sky-900">Queue Management System</span>
        </h1>
        <p className="mt-5 max-w-md text-slate-600">
          Book digital tokens, track your queue in real time, and receive timely
          updates for a simpler hospital visit.
        </p>

        <div className="mt-8 flex flex-wrap gap-4">
          <Link
            to="/login"
            className="rounded-xl bg-teal-700 px-7 py-3 font-medium text-white shadow-md transition-colors hover:bg-teal-800"
          >
            Get Started
          </Link>
          <button
            type="button"
            className="inline-flex items-center gap-2 rounded-xl border border-teal-200 bg-white/60 px-6 py-3 font-medium text-teal-800 transition-colors hover:bg-white"
          >
            <Play className="h-4 w-4" />
            Watch Demo
          </button>
        </div>
      </div>

      {/* Right: image + floating token card */}
      <div className="relative">
        <div className="aspect-[4/3] overflow-hidden rounded-[2rem] bg-gradient-to-br from-sky-100 to-teal-100 shadow-lg">
          <img
            src={HERO_IMAGE}
            alt="Doctor speaking with a patient at the hospital reception"
            className="h-full w-full object-cover"
            onError={(e) => {
              // Hide the broken image icon until you add /public/hero.jpg
              e.currentTarget.style.display = "none";
            }}
          />
        </div>
        <TokenCard />
      </div>
    </section>
  );
}

function FeatureStrip() {
  return (
    <section id="features" className="mx-auto max-w-6xl px-6 pb-16">
      <div className="grid grid-cols-2 gap-6 rounded-3xl bg-white/80 p-6 shadow-lg backdrop-blur sm:grid-cols-3 lg:grid-cols-6">
        {FEATURES.map(({ icon: Icon, title, text }) => (
          <div key={title} className="flex flex-col items-center text-center lg:items-start lg:text-left">
            <span className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-teal-50 text-teal-700">
              <Icon className="h-5 w-5" />
            </span>
            <h3 className="text-sm font-semibold text-slate-800">{title}</h3>
            <p className="mt-1 text-xs text-slate-500">{text}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-sky-50 via-cyan-50 to-white">
      <Navbar />
      <main>
        <Hero />
        <FeatureStrip />
      </main>
    </div>
  );
}