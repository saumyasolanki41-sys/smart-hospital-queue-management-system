import { useEffect, Suspense } from "react";
import { Link, useLocation } from "react-router-dom";
import { Ticket, Users, Bell, Stethoscope, ClipboardList, ShieldCheck } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import Footer from "../components/layout/Footer";
import About from "./About";
import Features from "./Features";
import { HowItWorksSection } from "./HowItWorks";
import HeroScene3D from "../components/hero/HeroScene3D";


const PALETTE = {
  "--color-primary": "#0d4b68",
  "--color-secondary": "#2183a0",
  "--color-accent": "#67e8f9",
};

/* ─── Hero section ───────────────────────────────────────────────────── */
function Hero() {
  return (
    <section
      id="home"
      className="mx-auto grid max-w-6xl items-center gap-10 px-6 pb-12 pt-12 md:grid-cols-2 md:pb-14 md:pt-20"
    >
      {/* Left — text content */}
      <div>
        <p className="mb-3 text-base font-medium text-[#2183a0]">
          Smarter Queues. Better Care.
        </p>
        <h1 className="text-4xl font-bold leading-tight text-[#0d4b68] sm:text-5xl">
          Smart Hospital
          <br />
          <span className="text-[#2183a0]">Queue Management System</span>
        </h1>
        <p className="mt-5 max-w-md text-slate-600">
          Book digital tokens, track your queue in real time, and receive timely
          updates for a simpler hospital visit.
        </p>

        <div className="mt-8 flex flex-wrap gap-4">
          <Link
            to="/Register"
            className="rounded-xl bg-[#0d4b68] px-7 py-3 font-medium text-white shadow-md transition-colors hover:bg-[#2183a0]"
          >
            Get Started
          </Link>
        </div>
      </div>

      {/* Right — 3D figure (no box, no background card) */}
      <div className="relative h-[460px] md:h-[540px]">
        <Suspense
          fallback={
            <div className="flex h-full w-full items-center justify-center">
              <span className="animate-pulse text-sm text-slate-400">
                Loading…
              </span>
            </div>
          }
        >
          <HeroScene3D />
        </Suspense>
      </div>
    </section>
  );
}

/* ─── Feature strip ──────────────────────────────────────────────────── */
const STRIP_ITEMS = [
  { icon: Ticket, title: "Digital Token Booking", text: "Skip the long queues." },
  { icon: Users, title: "Live Queue Tracking", text: "Know your wait time." },
  { icon: Bell, title: "Instant Notifications", text: "Get timely updates." },
  { icon: Stethoscope, title: "Doctor & Department", text: "Choose with ease." },
  { icon: ClipboardList, title: "Efficient Management", text: "For better operations." },
  { icon: ShieldCheck, title: "Secure & Reliable", text: "Your data is safe." },
];

function FeatureStrip() {
  return (
    <section aria-label="Key features" className="mx-auto max-w-6xl px-6 pb-20 md:pb-24">
      <ul className="grid grid-cols-2 gap-y-8 rounded-3xl bg-white/85 px-2 py-7 shadow-lg ring-1 ring-[#0d4b68]/10 backdrop-blur sm:grid-cols-3 xl:grid-cols-6 xl:gap-y-0 xl:divide-x xl:divide-[#0d4b68]/10">
        {STRIP_ITEMS.map(({ icon: Icon, title, text }) => (
          <li key={title} className="px-5">
            <span className="mb-3 flex h-11 w-11 items-center justify-center rounded-full bg-[#2183a0]/10 text-[#2183a0]">
              <Icon className="h-5 w-5" />
            </span>
            <h3 className="text-sm font-semibold leading-snug text-[#0d4b68]">{title}</h3>
            <p className="mt-1 text-xs text-slate-500">{text}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}

/* ─── Page root ──────────────────────────────────────────────────────── */
export default function LandingPage() {
  const { pathname, hash } = useLocation();

  useEffect(() => {
    if (pathname !== "/" || !hash) return;
    document
      .getElementById(hash.slice(1))
      ?.scrollIntoView({ behavior: "smooth" });
  }, [pathname, hash]);

  return (
    <div
      style={PALETTE}
      className="min-h-screen bg-gradient-to-br from-cyan-50 via-white to-cyan-50"
    >
      <Navbar />
      <main>
        <Hero />
        <FeatureStrip />
        <About />
        <HowItWorksSection />
        <Features />
      </main>
      <Footer />
    </div>
  );
}