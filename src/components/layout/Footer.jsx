import { HeartPulse, Mail, MapPin, Phone } from "lucide-react";
import { Link } from "react-router-dom";

const FOOTER_COLUMNS = [
  {
    heading: "Quick Links",
    links: [
      { label: "Home", to: "/" },
      { label: "About", to: "/about" },
      { label: "Features", to: "/#features" },
      { label: "How It Works", to: "/#how-it-works" },
    ],
  },
  {
    heading: "Features",
    links: [
      { label: "Digital Token Booking", to: "/departments" },
      { label: "Live Queue Tracking", to: "/queue" },
      { label: "Doctor & Department", to: "/departments" },
    ],
  },
  {
    heading: "Support",
    links: [
      { label: "Help Center", to: "/" },
      { label: "FAQs", to: "/" },
      { label: "Privacy Policy", to: "/" },
      { label: "Terms of Service", to: "/" },
    ],
  },
];

const SOCIAL_LINKS = [
  { label: "Facebook", href: "https://www.facebook.com", mark: "f" },
  { label: "LinkedIn", href: "https://www.linkedin.com", mark: "in" },
  { label: "Twitter", href: "https://www.twitter.com", mark: "X" },
  { label: "Instagram", href: "https://www.instagram.com", mark: "ig" },
];

function FooterLink({ label, to }) {
  return (
    <li>
      <Link
        to={to}
        className="text-sm text-cyan-50/75 transition-colors hover:text-white"
      >
        {label}
      </Link>
    </li>
  );
}

function ContactItem({ icon: Icon, children, href }) {
  const content = (
    <>
      <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-cyan-100/10 text-cyan-200">
        <Icon className="h-3 w-3" />
      </span>
      <span>{children}</span>
    </>
  );

  return (
    <li className="flex items-start gap-2 text-sm text-cyan-50/75">
      {href ? (
        <a href={href} className="flex items-start gap-2 transition-colors hover:text-white">
          {content}
        </a>
      ) : (
        content
      )}
    </li>
  );
}

export default function Footer() {
  return (
    <footer className="w-full bg-[#0d4b68] text-white">
      <div className="mx-auto w-full max-w-[1600px] px-6 py-8 sm:px-8 md:px-10 md:py-10 lg:px-12">
        <section className="mb-8 flex flex-col items-start justify-between gap-5 rounded-2xl bg-[#2183a0] px-6 py-5 sm:flex-row sm:items-center sm:px-7">
          <div>
            <h2 className="text-lg font-bold">Ready for a smoother hospital visit?</h2>
            <p className="mt-1 text-sm text-cyan-50/80">
              Book your digital token in seconds and skip the long queues.
            </p>
          </div>
          <Link
            to="/login"
            className="inline-flex shrink-0 items-center justify-center rounded-full bg-white px-8 py-3 text-sm font-semibold text-[#0d4b68] transition-colors hover:bg-cyan-50"
          >
            Get Started
          </Link>
        </section>

        <div className="grid gap-x-10 gap-y-10 border-b border-cyan-100/20 pb-10 sm:grid-cols-2 lg:grid-cols-[1.8fr_0.8fr_1fr_0.8fr_1.25fr]">
          <div>
            <Link to="/" className="inline-flex items-center gap-2">
              <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-cyan-200/20 text-cyan-200">
                <HeartPulse className="h-6 w-6" />
              </span>
              <span className="text-lg font-bold">Smart Hospital</span>
            </Link>
            <p className="mt-1 text-xs text-cyan-100/70">Smarter queues. Better care.</p>
            <p className="mt-2 max-w-60 text-xs leading-relaxed text-cyan-50/75">
              Digital tokens, real-time queue tracking and timely updates for a simpler visit.
            </p>
            <ul className="mt-4 flex gap-2.5">
              {SOCIAL_LINKS.map(({ label, href, mark }) => (
                <li key={label}>
                  <a
                    href={href}
                    aria-label={label}
                    target="_blank"
                    rel="noreferrer"
                    className="flex h-8 w-8 items-center justify-center rounded-full border border-cyan-100/30 bg-cyan-100/10 text-cyan-100 transition-colors hover:bg-cyan-100/25"
                  >
                    <span className="text-[10px] font-bold">{mark}</span>
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {FOOTER_COLUMNS.map(({ heading, links }) => (
            <nav key={heading} aria-label={heading}>
              <h2 className="mb-4 text-sm font-bold text-white after:mt-1.5 after:block after:h-px after:w-7 after:bg-cyan-300">
                {heading}
              </h2>
              <ul className="space-y-3">
                {links.map((link) => (
                  <FooterLink key={link.label} {...link} />
                ))}
              </ul>
            </nav>
          ))}

          <section aria-labelledby="footer-contact-heading">
            <h2
              id="footer-contact-heading"
              className="mb-4 text-sm font-bold text-white after:mt-1.5 after:block after:h-px after:w-7 after:bg-cyan-300"
            >
              Contact
            </h2>
            <ul className="space-y-3">
              <ContactItem icon={Mail} href="mailto:support@smarthospital.com">
                support@smarthospital.com
              </ContactItem>
              <ContactItem icon={Phone} href="tel:+919876543210">
                +91 98765 43210
              </ContactItem>
              <ContactItem icon={MapPin}>
                123 Health Avenue, New Delhi
              </ContactItem>
              <ContactItem icon={HeartPulse}>Mon – Sat, 8 AM – 8 PM</ContactItem>
            </ul>
          </section>
        </div>

        <div className="flex flex-col gap-3 pt-5 text-xs text-cyan-100/65 sm:flex-row sm:items-center sm:justify-between">
          <p>© {new Date().getFullYear()} Smart Hospital. All rights reserved.</p>
          <nav aria-label="Legal links" className="flex flex-wrap gap-x-2">
            <Link to="/" className="hover:text-white">Privacy Policy</Link>
            <span aria-hidden="true">•</span>
            <Link to="/" className="hover:text-white">Terms of Service</Link>
            <span aria-hidden="true">•</span>
            <Link to="/" className="hover:text-white">Cookie Policy</Link>
          </nav>
        </div>
      </div>
    </footer>
  );
}
