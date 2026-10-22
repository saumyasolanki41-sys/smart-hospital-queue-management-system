import { Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import Sidebar from "./Sidebar";

export default function AppShell() {
  const { user } = useAuth();

  if (!user) return <Outlet />;

  return (
    <div className="min-h-screen bg-gradient-to-br from-secondary/5 via-accent/5 to-white lg:flex">
      <Sidebar />
      <div className="min-w-0 flex-1">
        <Outlet />
      </div>
    </div>
  );
}