import { Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import Sidebar from "./Sidebar";
import DashboardBackground from "./DashboardBackground";

export default function AppShell() {
  const { user } = useAuth();

  if (!user) return <Outlet />;

  return (
    <DashboardBackground>
      <div className="min-h-screen lg:flex">
        <Sidebar />
        <div className="min-w-0 flex-1">
          <Outlet />
        </div>
      </div>
    </DashboardBackground>
  );
}
