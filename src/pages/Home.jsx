// src/pages/Home.jsx — temporary placeholder. Access is handled by <ProtectedRoute /> in App.jsx.
import { useAuth } from "../components/context/AuthContext";
import Navbar from "../components/layout/Navbar";

export default function Home() {
  const { user } = useAuth();

  return (
    <div className="min-h-screen bg-gradient-to-br from-sky-50 via-cyan-50 to-white">
      <Navbar />
      <main className="mx-auto max-w-6xl px-6 py-10">
        <h1 className="text-3xl font-bold text-slate-900">Welcome, {user.name}</h1>
        <p className="mt-2 text-slate-600">
          Signed in as {user.email} ({user.role}).
        </p>
        <p className="mt-6 text-sm text-slate-500">
          Placeholder page. Replace it with the real patient home later.
        </p>
      </main>
    </div>
  );
}