import { useEffect, Suspense } from "react";
import { Link, useLocation } from "react-router-dom";
import { HeartPulse, Clock } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import Footer from "../components/layout/Footer";
import About from "./About";
import Features from "./Features";
import { HowItWorksSection } from "./HowItWorks";
import HeroScene3D from "../components/hero/HeroScene3D";


/* ─── Hero section ───────────────────────────────────────────────────── */
function Hero() {
  return (
    <section
      id="home"
      className="mx-auto grid max-w-6xl items-center gap-10 px-6 pb-24 pt-12 md:grid-cols-2 md:pb-28 md:pt-20"
    >
      {/* Left — text content */}
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
