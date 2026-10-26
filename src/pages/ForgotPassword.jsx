import { useState } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import {
  forgotPassword,
  resetPassword,
  validateEmail,
  validateNewPassword,
  isValidOtp,
  errorMessage,
} from "../api/auth";
import { useAuth, ROLE_HOME } from "../components/context/AuthContext";
import {
  AuthShell,
  TextField,
  PasswordField,
  Banner,
  SubmitButton,
  useCooldown,
} from "../components/auth/AuthParts";

export default function ForgotPassword() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();

  const [step, setStep] = useState("email"); 
  const [email, setEmail] = useState(location.state?.email ?? ""); 
  const [otp, setOtp] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [errors, setErrors] = useState({});
  const [serverError, setServerError] = useState("");
  const [loading, setLoading] = useState(false);
  const [cooldown, startCooldown] = useCooldown();

  if (user) return <Navigate to={ROLE_HOME[user.role] ?? "/"} replace />;

  const cleanEmail = email.trim().toLowerCase();

  
  async function sendCode() {
    setLoading(true);
    setServerError("");
    try {
      await forgotPassword({ email: cleanEmail });
      startCooldown(60);
      return true;
    } catch (err) {
      setServerError(errorMessage(err));
      return false;
    } finally {
      setLoading(false);
    }
  }

  async function handleEmail(e) {
    e.preventDefault();
    const found = { email: validateEmail(email) };
    setErrors(found);
    if (found.email) return;

    if (await sendCode()) {
      setOtp("");
      setStep("reset");
    }
  }

  async function handleReset(e) {
    e.preventDefault();
    const found = {
      otp: isValidOtp(otp) ? "" : "Enter the 6-digit code.",
      password: validateNewPassword(password),
      confirm: password === confirm ? "" : "The passwords don't match.",
    };
    setErrors(found);
    if (Object.values(found).some(Boolean)) return;

    setLoading(true);
    setServerError("");
    try {
      await resetPassword({ email: cleanEmail, otp, newPassword: password });
      // No login happens here: send them to the login page with a confirmation.
      navigate("/login", { state: { passwordReset: true, registeredEmail: cleanEmail } });
    } catch (err) {
      setServerError(errorMessage(err));
      setLoading(false);
    }
  }

  if (step === "reset") {
    return (
      <AuthShell
        title="Reset your password"
        subtitle={`If ${cleanEmail} has a password account, we've sent a 6-digit code to it. The code expires in 5 minutes.`}
        footer={
          <button
            type="button"
            onClick={() => {
              setStep("email");
              setServerError("");
              setErrors({});
            }}
            className="font-medium text-primary/70 hover:underline"
          >
            Use a different email
          </button>
        }
      >
        <form onSubmit={handleReset} className="space-y-4" noValidate>
          {serverError && <Banner>{serverError}</Banner>}
          <TextField
            id="otp"
            label="Verification code"
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
            error={errors.otp}
            inputMode="numeric"
            autoComplete="one-time-code"
            placeholder="000000"
            maxLength={6}
            className="text-center text-2xl tracking-[0.5em]"
          />
          <PasswordField
            id="password"
            label="New password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            error={errors.password}
            autoComplete="new-password"
          />
          <PasswordField
            id="confirm"
            label="Confirm new password"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            error={errors.confirm}
            autoComplete="new-password"
          />
          <SubmitButton loading={loading}>Update password</SubmitButton>
          <button
            type="button"
            onClick={sendCode}
            disabled={cooldown > 0 || loading}
            className="w-full text-sm font-medium text-primary/70 hover:underline disabled:cursor-not-allowed disabled:text-slate-400 disabled:no-underline"
          >
            {cooldown > 0 ? `Resend code in ${cooldown}s` : "Resend code"}
          </button>
          <p className="text-center text-xs text-slate-500">
            No email? Check your spam folder. If you signed up with Google, there's no password to reset. Go back
            to login and use "Continue with Google".
          </p>
        </form>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      title="Forgot your password?"
      subtitle="Enter your email and we'll send you a code to set a new one."
      footer={
        <>
          Remembered it?{" "}
          <Link to="/login" className="font-medium text-primary/70 hover:underline">
            Back to login
          </Link>
        </>
      }
    >
      <form onSubmit={handleEmail} className="space-y-4" noValidate>
        {serverError && <Banner>{serverError}</Banner>}
        <TextField
          id="email"
          type="email"
          label="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          error={errors.email}
          autoComplete="email"
        />
        <SubmitButton loading={loading}>Send reset code</SubmitButton>
      </form>
    </AuthShell>
  );
}