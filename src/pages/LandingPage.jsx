import { useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import {
  HeartPulse,
  Clock,
  Play,
} from "lucide-react";
import Navbar from "../components/layout/Navbar";
import Footer from "../components/layout/Footer";
import About from "./About";
import Features from "./Features";
import { HowItWorksSection } from "./HowItWorks";

const HERO_IMAGE = "/hero.jpg";

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
            to="/Register"
            className="rounded-xl bg-primary/70 px-7 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80"
          >
            Get Started
          </Link>
          {/* <button
            type="button"
            className="inline-flex items-center gap-2 rounded-xl border border-primary/20 bg-white/60 px-6 py-3 font-medium text-primary/80 transition-colors hover:bg-white"
          >
            <Play className="h-4 w-4" />
            Watch Demo
          </button> */}
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
              
              e.currentTarget.style.display = "none";
            }}
          />
        </div>
        <TokenCard />
      </div>
    </section>
  );
}

export default function LandingPage() {
  const { pathname, hash } = useLocation();

  useEffect(() => {
    if (pathname !== "/" || !hash) return;
    document.getElementById(hash.slice(1))?.scrollIntoView({ behavior: "smooth" });
  }, [pathname, hash]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white">
      <Navbar />
      <main>
        <Hero />
        <About />
        <HowItWorksSection />
        <Features />
      </main>
      <Footer />
    </div>
  );
}