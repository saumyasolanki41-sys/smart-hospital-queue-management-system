import { useState } from "react";
import { Link, Navigate, useLocation } from "react-router-dom";
import {
  login,
  verifyLogin,
  validateEmail,
  isValidOtp,
  errorMessage,
  roleMatches,
  optionForRole,
  roleMismatchMessage,
} from "../api/auth";
import { useAuth, ROLE_HOME } from "../components/context/AuthContext";
import GoogleButton from "../components/auth/GoogleButton";
import {
  AuthShell,
  TextField,
  PasswordField,
  Banner,
  SubmitButton,
  RoleSelector,
  useCooldown,
} from "../components/auth/AuthParts";

export default function Login() {
  const location = useLocation();
  const { user, signIn } = useAuth();
  const registeredEmail = location.state?.registeredEmail;

  const [step, setStep] = useState("credentials"); 
  const [role, setRole] = useState("patient"); 
  const [form, setForm] = useState({ email: registeredEmail ?? "", password: "" });
  const [challengeId, setChallengeId] = useState("");
  const [otp, setOtp] = useState("");
  const [errors, setErrors] = useState({});
  const [serverError, setServerError] = useState("");
  const [loading, setLoading] = useState(false);
  const [cooldown, startCooldown] = useCooldown();

  if (user) return <Navigate to={location.state?.from ?? ROLE_HOME[user.role] ?? "/"} replace />;

  const email = form.email.trim().toLowerCase();
  const update = (field) => (e) => setForm((f) => ({ ...f, [field]: e.target.value }));

  async function requestCode() {
    setLoading(true);
    setServerError("");
    try {
      const data = await login({ email, password: form.password });
      setChallengeId(data.challengeId);
      startCooldown(60);
      return true;
    } catch (err) {
      setServerError(errorMessage(err));
      if (err.code === "LOGIN_COOLDOWN") startCooldown(60);
      return false;
    } finally {
      setLoading(false);
    }
  }

  async function handleCredentials(e) {
    e.preventDefault();
    const found = {
      email: validateEmail(form.email),
      password: form.password ? "" : "Enter your password.",
    };
    setErrors(found);
    if (Object.values(found).some(Boolean)) return;

    if (await requestCode()) {
      setOtp("");
      setStep("otp");
    }
  }

  async function handleVerify(e) {
    e.preventDefault();
    if (!isValidOtp(otp)) {
      setErrors({ otp: "Enter the 6-digit code." });
      return;
    }
    setErrors({});
    setLoading(true);
    setServerError("");
    try {
      const data = await verifyLogin({ challengeId, otp });
      if (!roleMatches(role, data.user.role)) {
        setRole(optionForRole(data.user.role));
        setServerError(roleMismatchMessage(data.user.role));
        setStep("credentials");
        setLoading(false);
        return;
      }
      signIn(data);
    } catch (err) {
      setServerError(errorMessage(err));
      setLoading(false);
    }
  }

  if (step === "otp") {
    return (
      <AuthShell
        title="Enter your login code"
        subtitle={`We sent a 6-digit code to ${email}.`}
        footer={
          <button
            type="button"
            onClick={() => {
              setStep("credentials");
              setServerError("");
              setErrors({});
            }}
            className="font-medium text-primary/70 hover:underline"
          >
            Back to login
          </button>
        }
      >
        <form onSubmit={handleVerify} className="space-y-4" noValidate>
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
          <SubmitButton loading={loading}>Verify and log in</SubmitButton>
          <button
            type="button"
            onClick={requestCode}
            disabled={cooldown > 0 || loading}
            className="w-full text-sm font-medium text-primary/70 hover:underline disabled:cursor-not-allowed disabled:text-slate-400 disabled:no-underline"
          >
            {cooldown > 0 ? `Resend code in ${cooldown}s` : "Resend code"}
          </button>
        </form>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      title="Welcome back"
      subtitle="Log in to book appointments and track your queue."
      footer={
        <>
          New here?{" "}
          <Link to="/register" className="font-medium text-primary/70 hover:underline">
            Create an account
          </Link>
        </>
      }
    >
      <form onSubmit={handleCredentials} className="space-y-4" noValidate>
        <RoleSelector value={role} onChange={setRole} />
        {registeredEmail && !serverError && (
          <Banner type="success">Account created. Log in to continue.</Banner>
        )}
        {serverError && <Banner>{serverError}</Banner>}
        <TextField
          id="email"
          type="email"
          label="Email"
          value={form.email}
          onChange={update("email")}
          error={errors.email}
          autoComplete="email"
        />
        <PasswordField
          id="password"
          label="Password"
          value={form.password}
          onChange={update("password")}
          error={errors.password}
          autoComplete="current-password"
        />
        <SubmitButton loading={loading}>Send login code</SubmitButton>
      </form>
      <GoogleButton role={role} onWrongRole={(actual) => setRole(optionForRole(actual))} />
    </AuthShell>
  );
}