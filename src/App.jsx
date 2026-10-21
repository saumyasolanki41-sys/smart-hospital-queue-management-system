import { Routes, Route } from "react-router-dom";
import { GoogleOAuthProvider } from "@react-oauth/google";
import { AuthProvider } from "./components/context/AuthContext";
import ProtectedRoute from "./components/layout/ProtectedRoute";
import LandingPage from "./pages/LandingPage";
import About from "./pages/About";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Departments from "./pages/Departments";
import Home from "./pages/Home";
import MyQueue from "./pages/MyQueue";
import QueueStatus from "./pages/QueueStatus";
import QueueDashboard from "./pages/QueueDashboard";
import AmbulanceDashboard from "./pages/AmbulanceDashboard";

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID ?? "";

export default function App() {
  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
      <AuthProvider>
        <Routes>
          {/* Public */}
          <Route path="/" element={<LandingPage />} />
          <Route path="/about" element={<About />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/departments" element={<Departments />} />

          {/* Patients only */}
          <Route element={<ProtectedRoute roles={["patient"]} />}>
            <Route path="/home" element={<Home />} />
            <Route path="/queue" element={<MyQueue />} />
            <Route path="/queue/:tokenId" element={<QueueStatus />} />
          </Route>

          {/* Staff (admin, receptionist) manage any doctor's queue and the ambulances */}
          <Route element={<ProtectedRoute roles={["receptionist", "admin"]} />}>
            <Route path="/staff" element={<QueueDashboard mode="staff" />} />
            <Route path="/ambulance" element={<AmbulanceDashboard />} />
          </Route>

          {/* Doctors manage only their own queue */}
          <Route element={<ProtectedRoute roles={["doctor"]} />}>
            <Route path="/doctor" element={<QueueDashboard mode="doctor" />} />
          </Route>
        </Routes>
      </AuthProvider>
    </GoogleOAuthProvider>
  );
}