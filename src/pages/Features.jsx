const FEATURES = [
  {
    image: "/Features1.png",
    title: "Browse Doctors by Category",
    description: "Explore doctors by department and find the care you need.",
  },
  {
    image: "/Features2.png",
    title: "Join Your Doctor's Queue",
    description: "Choose your preferred doctor and join their queue when they are available.",
  },
  {
    image: "/Features3.png",
    title: "Track Your Token in Real Time",
    description: "Follow your token number and see your estimated waiting time.",
  },
  {
    image: "/Features4.png",
    title: "Ambulance Tracking",
    description: "Staff can track ambulances in real time.",
  },
];

export default function Features() {
  return (
    <section
      id="features"
      className="mx-auto max-w-6xl scroll-mt-6 px-6 pb-20"
      aria-labelledby="features-heading"
    >
      <header className="mb-6">
        <p className="mb-2 text-base font-medium text-primary/70">What you can do</p>
        <h2 id="features-heading" className="text-3xl font-bold text-slate-900">
          Features
        </h2>
      </header>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {FEATURES.map(({ image, title, description }) => (
          <article
            key={title}
            className="overflow-hidden rounded-2xl bg-white/90 shadow-lg"
          >
            <img
              src={image}
              alt={title}
              className="aspect-video w-full object-cover"
            />
            <div className="p-4">
              <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
              <p className="mt-1 text-sm text-slate-600">{description}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
