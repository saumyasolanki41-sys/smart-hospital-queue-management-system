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

// Public Google web client ID (set in .env as VITE_GOOGLE_CLIENT_ID). Never put a client secret here.
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

          {/* Any signed-in user */}
          <Route element={<ProtectedRoute />}>
            <Route path="/home" element={<Home />} />
          </Route>

          {/* Patients only */}
          <Route element={<ProtectedRoute roles={["patient"]} />}>
            <Route path="/queue" element={<MyQueue />} />
            <Route path="/queue/:tokenId" element={<QueueStatus />} />
          </Route>

        </Routes>
      </AuthProvider>
    </GoogleOAuthProvider>
  );
}