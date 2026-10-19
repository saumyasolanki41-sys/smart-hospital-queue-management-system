import { Link } from "react-router-dom";
import {
  HeartPulse,
  Clock,
  Play,
  Ticket,
  Users,
  Bell,
  Stethoscope,
  ClipboardList,
  ShieldCheck,
} from "lucide-react";
import Navbar from "../components/layout/Navbar";
import About from "./About";

// Put your hero photo in the /public folder as hero.jpg
const HERO_IMAGE = "/hero.jpg";

const FEATURES = [
  { icon: Ticket, title: "Digital Token Booking", text: "Skip the long queues." },
  { icon: Users, title: "Live Queue Tracking", text: "Know your wait time." },
  { icon: Bell, title: "Instant Notifications", text: "Get timely updates." },
  { icon: Stethoscope, title: "Doctor & Department", text: "Choose with ease." },
  { icon: ClipboardList, title: "Efficient Management", text: "For better operations." },
  { icon: ShieldCheck, title: "Secure & Reliable", text: "Your data is safe." },
];

function TokenCard() {
  return (
    <div className="absolute -left-4 bottom-8 w-52 rounded-2xl bg-white/95 p-4 shadow-xl backdrop-blur sm:-left-10">
      <div className="flex items-center gap-3">
        <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-secondary/10 text-primary/70">
          <HeartPulse className="h-5 w-5" />
        </span>
        <div>
          <p className="text-xs text-slate-500">Your Token No.</p>
          <p className="text-lg font-bold text-slate-800">A-023</p>
        </div>
      </div>
      <div className="mt-3 flex items-center gap-3 border-t border-slate-100 pt-3">
        <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-secondary/10 text-primary/70">
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
        <p className="mb-3 text-base font-medium text-primary/70">
          Smarter Queues. Better Care.
        </p>
        <h1 className="text-4xl font-bold leading-tight text-slate-900 sm:text-5xl">
          Smart Hospital
          <br />
          <span className="text-secondary/90">Queue Management System</span>
        </h1>
        <p className="mt-5 max-w-md text-slate-600">
          Book digital tokens, track your queue in real time, and receive timely
          updates for a simpler hospital visit.
        </p>

        <div className="mt-8 flex flex-wrap gap-4">
          <Link
            to="/login"
            className="rounded-xl bg-primary/70 px-7 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80"
          >
            Get Started
          </Link>
          <button
            type="button"
            className="inline-flex items-center gap-2 rounded-xl border border-primary/20 bg-white/60 px-6 py-3 font-medium text-primary/80 transition-colors hover:bg-white"
          >
            <Play className="h-4 w-4" />
            Watch Demo
          </button>
        </div>
      </div>

      {/* Right: image + floating token card */}
      <div className="relative">
        <div className="aspect-[4/3] overflow-hidden rounded-[2rem] bg-gradient-to-br from-secondary/10 to-primary/10 shadow-lg">
          <img
            src={HERO_IMAGE}
            alt="Doctor speaking with a patient at the hospital reception"
            className="h-full w-full object-cover"
            onError={(e) => {
              // Hide the broken image icon until /public/hero.jpg exists
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
          <div
            key={title}
            className="flex flex-col items-center text-center lg:items-start lg:text-left"
          >
            <span className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-primary/5 text-primary/70">
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
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white">
      <Navbar />
      <main>
        <Hero />
        <FeatureStrip />
        <About />
      </main>
    </div>
  );
}