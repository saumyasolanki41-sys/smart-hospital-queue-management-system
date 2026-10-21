import Navbar from "../components/layout/Navbar";
import Footer from "../components/layout/Footer";

const STEPS = [
  {
    title: "Book your token",
    text: "Pick a department and doctor, then choose a time that suits you.",
    image: "/Howitworks1.png",
    alt: "Screenshot showing how to book a token",
  },
  {
    title: "Track your turn",
    text: "Follow your position in the queue and your estimated wait from anywhere.",
    image: "/Howitworks2.png",
    alt: "Screenshot showing how to track your queue position",
  },
  {
    title: "Get called in",
    text: "Staff call the next patient, and you walk in when it's your turn.",
    image: "/Howitworks3.png",
    alt: "Screenshot showing a patient being called in",
  },
];

export function HowItWorksSection() {
  return (
    <section
      id="how-it-works"
      className="mx-auto max-w-6xl px-6 pb-20 pt-10 md:pt-16"
      aria-labelledby="how-it-works-heading"
    >
      <header className="mb-8">
        <p className="mb-2 text-base font-medium text-primary/70">A simpler hospital visit</p>
        <h2 id="how-it-works-heading" className="text-3xl font-bold text-slate-900 sm:text-4xl">
          How it works
        </h2>
      </header>

      <ol className="grid gap-6 md:grid-cols-3">
        {STEPS.map(({ title, text, image, alt }, index) => (
          <li key={title} className="overflow-hidden rounded-3xl bg-white/90 shadow-lg">
            <img
              src={image}
              alt={alt}
              className="aspect-[4/3] w-full bg-primary/5 object-contain"
            />
            <div className="p-6">
              <p className="mb-2 text-sm font-semibold text-primary/70">Step {index + 1}</p>
              <h3 className="text-xl font-semibold text-slate-900">{title}</h3>
              <p className="mt-2 text-slate-600">{text}</p>
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}

export default function HowItWorks() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white">
      <Navbar />
      <main>
        <HowItWorksSection />
      </main>
      <Footer />
    </div>
  );
}
