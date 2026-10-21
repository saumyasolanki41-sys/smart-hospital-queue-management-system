import { HeartPulse } from "lucide-react";
import { Link } from "react-router-dom";

const FOOTER_GROUPS = [
  {
    heading: "Explore",
    links: [
      { label: "Home", to: "/" },
      { label: "About", to: "/about" },
      { label: "Departments", to: "/departments" },
      { label: "How it works", to: "/#how-it-works" },
    ],
  },
  {
    heading: "Account",
    links: [
      { label: "Login", to: "/login" },
      { label: "Register", to: "/register" },
      { label: "Contact", to: "/contact" },
    ],
  },
];

export default function Footer() {
  return (
    <footer className="border-t border-primary/10 bg-white/70">
      <div className="mx-auto max-w-6xl px-6 py-10">
        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          <Link to="/" className="flex items-center gap-2 self-start">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/60 text-white">
              <HeartPulse className="h-5 w-5" />
            </span>
            <span className="font-semibold text-slate-800">Smart Hospital</span>
          </Link>

          {FOOTER_GROUPS.map(({ heading, links }) => (
            <nav key={heading} aria-label={heading}>
              <h2 className="mb-3 text-sm font-semibold text-slate-800">{heading}</h2>
              <ul className="space-y-2">
                {links.map(({ label, to }) => (
                  <li key={label}>
                    <Link
                      to={to}
                      className="text-sm text-slate-600 transition-colors hover:text-primary/70"
                    >
                      {label}
                    </Link>
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>

        <p className="mt-8 border-t border-primary/10 pt-5 text-sm text-slate-500">
          © {new Date().getFullYear()} Smart Hospital
        </p>
      </div>
    </footer>
  );
}
