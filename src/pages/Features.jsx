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
];

export default function Features() {
  return (
    <section
      id="features"
      className="mx-auto max-w-6xl scroll-mt-6 px-6 pb-20"
      aria-labelledby="features-heading"
    >
      <header className="mb-8">
        <p className="mb-2 text-base font-medium text-primary/70">What you can do</p>
        <h2 id="features-heading" className="text-3xl font-bold text-slate-900">
          Features
        </h2>
      </header>

      <div className="grid gap-6 md:grid-cols-2">
        {FEATURES.map(({ image, title, description }, index) => (
          <article
            key={title}
            className={`overflow-hidden rounded-3xl bg-white/90 shadow-lg ${
              index === 2 ? "md:col-span-2 md:mx-auto md:w-1/2" : ""
            }`}
          >
            <img
              src={image}
              alt={title}
              className="aspect-video w-full object-cover"
            />
            <div className="p-6">
              <h3 className="text-xl font-semibold text-slate-900">{title}</h3>
              <p className="mt-2 text-slate-600">{description}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
