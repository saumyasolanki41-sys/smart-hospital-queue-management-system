import { Routes, Route } from "react-router-dom";
import { GoogleOAuthProvider } from "@react-oauth/google";
import { AuthProvider } from "./components/context/AuthContext";
import ProtectedRoute from "./components/layout/ProtectedRoute";
import AppShell from "./components/layout/AppShell";
import LandingPage from "./pages/LandingPage";
import About from "./pages/About";
import Login from "./pages/Login";
import Register from "./pages/Register";
import ForgotPassword from "./pages/ForgotPassword";
import Departments from "./pages/Departments";
import DoctorProfile from "./pages/DoctorProfile";
import Home from "./pages/Home";
import MyQueue from "./pages/MyQueue";
import VisitHistory from "./pages/VisitHistory";
import QueueStatus from "./pages/QueueStatus";
import QueueDashboard from "./pages/QueueDashboard";
import AmbulanceDashboard from "./pages/AmbulanceDashboard";
import RequestAmbulance from "./pages/RequestAmbulance";
import ChatbotWidget from "./components/chatbot/ChatbotWidget";

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID ?? "";

export default function App() {
  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />

          <Route element={<AppShell />}>
            {/* Public */}
            <Route path="/" element={<LandingPage />} />
            <Route path="/about" element={<About />} />
            <Route path="/departments" element={<Departments />} />
            <Route path="/doctors/:doctorId" element={<DoctorProfile />} />

            {/* Patients only */}
            <Route element={<ProtectedRoute roles={["patient"]} />}>
              <Route path="/home" element={<Home />} />
              <Route path="/queue" element={<MyQueue />} />
              <Route path="/history" element={<VisitHistory />} />
              <Route path="/queue/:tokenId" element={<QueueStatus />} />
              <Route path="/request-ambulance" element={<RequestAmbulance />} />
            </Route>

            <Route element={<ProtectedRoute roles={["receptionist", "admin"]} />}>
              <Route path="/staff" element={<QueueDashboard mode="staff" />} />
              <Route path="/ambulance" element={<AmbulanceDashboard />} />
            </Route>

            <Route element={<ProtectedRoute roles={["doctor"]} />}>
              <Route path="/doctor" element={<QueueDashboard mode="doctor" />} />
            </Route>
          </Route>
        </Routes>
        <ChatbotWidget />
      </AuthProvider>
    </GoogleOAuthProvider>
  );
}
