import { Routes, Route } from "react-router-dom";
import { GoogleOAuthProvider } from "@react-oauth/google";
import { AuthProvider } from "./components/context/AuthContext";
import ProtectedRoute from "./components/layout/ProtectedRoute";
import AppShell from "./components/layout/AppShell";
import LandingPage from "./pages/LandingPage";
import About from "./pages/About";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Departments from "./pages/Departments";
import DoctorProfile from "./pages/DoctorProfile";
import Home from "./pages/Home";
import MyQueue from "./pages/MyQueue";
import QueueStatus from "./pages/QueueStatus";
import QueueDashboard from "./pages/QueueDashboard";
import AmbulanceDashboard from "./pages/AmbulanceDashboard";
import RequestAmbulance from "./pages/RequestAmbulance";

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID ?? "";

export default function App() {
  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
      <AuthProvider>
        <Routes>
          {/* These two have their own centered layout */}
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />

          {/* Everything else: logged-in users get the left sidebar, visitors get the top navbar */}
          <Route element={<AppShell />}>
            {/* Public */}
            <Route path="/" element={<LandingPage />} />
            <Route path="/about" element={<About />} />
            <Route path="/departments" element={<Departments />} />
            <Route path="/doctors/:doctorId" element={<DoctorProfile />} />
            {/* Add your other public pages here, e.g. your "How it works" page */}

            {/* Patients only */}
            <Route element={<ProtectedRoute roles={["patient"]} />}>
              <Route path="/home" element={<Home />} />
              <Route path="/queue" element={<MyQueue />} />
              <Route path="/queue/:tokenId" element={<QueueStatus />} />
              <Route path="/request-ambulance" element={<RequestAmbulance />} />
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
          </Route>
        </Routes>
      </AuthProvider>
    </GoogleOAuthProvider>
  );
}