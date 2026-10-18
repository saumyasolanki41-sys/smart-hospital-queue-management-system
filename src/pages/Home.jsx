//temporary placeholder
import { Navigate } from "react-router-dom";
import { useAuth } from "../components/context/AuthContext";

export default function Home() {
  const { user, signOut } = useAuth();
  if (!user) return <Navigate to="/login" replace />;

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-sky-50 via-cyan-50 to-white p-6">
      <div className="w-full max-w-md rounded-3xl bg-white p-8 text-center shadow-lg">
        <h1 className="text-2xl font-bold text-slate-900">Welcome, {user.name}</h1>
        <p className="mt-2 text-slate-600">
          Signed in as {user.email} ({user.role})
        </p>
        <p className="mt-4 text-sm text-slate-500">
          Placeholder page. Replace it with the real patient home later.
        </p>
        <button
          type="button"
          onClick={signOut}
          className="mt-6 rounded-xl border border-teal-600 px-6 py-2 font-medium text-teal-700 hover:bg-teal-50"
        >
          Log out
        </button>
      </div>
    </div>
  );
}