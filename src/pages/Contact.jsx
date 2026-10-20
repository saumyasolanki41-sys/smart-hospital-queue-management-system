import Footer from "../components/layout/Footer";
import Navbar from "../components/layout/Navbar";

export default function Contact() {
  return (
    <div className="flex min-h-screen flex-col bg-gradient-to-br from-secondary/5 via-accent/5 to-white">
      <Navbar />
      <main className="mx-auto flex w-full max-w-6xl flex-1 items-center px-6 py-20">
        <section className="w-full rounded-3xl bg-white/90 p-8 text-center shadow-lg sm:p-12">
          <p className="mb-3 text-base font-medium text-primary/70">Contact</p>
          <h1 className="text-3xl font-bold text-slate-900">We'd love to hear from you</h1>
          <p className="mx-auto mt-4 max-w-xl text-slate-600">
            Our contact page is coming soon. Please check back later for ways to get in touch.
          </p>
        </section>
      </main>
      <Footer />
    </div>
  );
}