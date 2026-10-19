import { Link } from "react-router-dom";
import {
  Users,
  Stethoscope,
  ClipboardList,
  Heart,
  Hand,
  Bone,
  Check,
} from "lucide-react";

const AUDIENCES = [
  {
    icon: Users,
    title: "For patients",
    points: [
      "Book a digital token from your phone",
      "See how many patients are ahead of you",
      "Check your estimated waiting time",
    ],
  },
  {
    icon: ClipboardList,
    title: "For staff",
    points: [
      "See who is being served right now",
      "Call the next patient with one click",
      "Update the waiting queue as things change",
    ],
  },
  {
    icon: Stethoscope,
    title: "For doctors",
    points: [
      "View the current patient and who is next",
      "Stay on schedule with a clear daily list",
      "Spend less time on front-desk coordination",
    ],
  },
];

const STEPS = [
  {
    title: "Book your token",
    text: "Pick a department and doctor, then choose a time that suits you.",
  },
  {
    title: "Track your turn",
    text: "Follow your position in the queue and your estimated wait from anywhere.",
  },
  {
    title: "Get called in",
    text: "Staff call the next patient, and you walk in when it's your turn.",
  },
];

const DEPARTMENTS = [
  { icon: Heart, name: "Cardiology", text: "Heart and blood vessel care." },
  { icon: Hand, name: "Dermatology", text: "Skin, hair and nail care." },
  { icon: Bone, name: "Orthopaedics", text: "Bone, joint and muscle care." },
];

export default function About() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white">

      <main>
        {/* Intro */}
        <section id="about" className="mx-auto max-w-6xl px-6 pb-14 pt-10 md:pt-16">
          <p className="mb-3 text-base font-medium text-primary/70">About Smart Hospital</p>
          <h1 className="max-w-3xl text-4xl font-bold leading-tight text-slate-900 sm:text-5xl">
            Hospital visits should be about care, not crowded waiting rooms.
          </h1>
          <p className="mt-5 max-w-2xl text-lg text-slate-600">
            Smart Hospital replaces paper tokens and guesswork with a live digital
            queue. Patients know exactly where they stand, and staff and doctors
            get one clear view of who is waiting and who is next.
          </p>
        </section>

        {/* Audiences */}
        <section className="mx-auto max-w-6xl px-6 pb-16">
          <h2 className="mb-6 text-2xl font-semibold text-slate-900">
            One system, three roles
          </h2>
          <div className="grid gap-6 md:grid-cols-3">
            {AUDIENCES.map(({ icon: Icon, title, points }) => (
              <div key={title} className="rounded-3xl bg-white/90 p-6 shadow-lg">
                <span className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-primary/5 text-primary/70">
                  <Icon className="h-6 w-6" />
                </span>
                <h3 className="text-lg font-semibold text-slate-800">{title}</h3>
                <ul className="mt-4 space-y-3">
                  {points.map((point) => (
                    <li key={point} className="flex items-start gap-2 text-sm text-slate-600">
                      <Check className="mt-0.5 h-4 w-4 shrink-0 text-primary/60" />
                      {point}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>

        {/* How it works */}
        <section id="how-it-works" className="mx-auto max-w-6xl px-6 pb-16">
          <h2 className="mb-6 text-2xl font-semibold text-slate-900">How it works</h2>
          <ol className="grid gap-6 md:grid-cols-3">
            {STEPS.map((step, i) => (
              <li key={step.title} className="flex gap-4">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/70 text-sm font-semibold text-white">
                  {i + 1}
                </span>
                <div>
                  <h3 className="font-semibold text-slate-800">{step.title}</h3>
                  <p className="mt-1 text-sm text-slate-600">{step.text}</p>
                </div>
              </li>
            ))}
          </ol>
        </section>

        {/* Departments */}
        <section className="mx-auto max-w-6xl px-6 pb-16">
          <h2 className="mb-6 text-2xl font-semibold text-slate-900">
            Departments we cover
          </h2>
          <div className="grid gap-6 sm:grid-cols-3">
            {DEPARTMENTS.map(({ icon: Icon, name, text }) => (
              <div
                key={name}
                className="flex items-center gap-4 rounded-2xl bg-white/90 p-5 shadow-md"
              >
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-secondary/10 text-primary/70">
                  <Icon className="h-6 w-6" />
                </span>
                <div>
                  <h3 className="font-semibold text-slate-800">{name}</h3>
                  <p className="text-sm text-slate-500">{text}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Call to action */}
        <section className="mx-auto max-w-6xl px-6 pb-20">
          <div className="flex flex-col items-start justify-between gap-6 rounded-3xl bg-primary/70 p-8 text-white md:flex-row md:items-center md:p-10">
            <div>
              <h2 className="text-2xl font-semibold">Ready to skip the wait?</h2>
              <p className="mt-1 text-primary/5">
                Book a token and follow your turn in real time.
              </p>
            </div>
            <Link
              to="/login"
              className="rounded-xl bg-white px-7 py-3 font-medium text-primary/80 transition-colors hover:bg-primary/5"
            >
              Get Started
            </Link>
          </div>
        </section>
      </main>
    </div>
  );
}