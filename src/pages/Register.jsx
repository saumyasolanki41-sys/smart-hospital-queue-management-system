// src/pages/Register.jsx
import { useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import {
  register,
  verifyRegistration,
  validateName,
  validateEmail,
  validateNewPassword,
  isValidOtp,
  errorMessage,
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

export default function Register() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [step, setStep] = useState("details"); // "details" -> "otp"
  const [role, setRole] = useState("patient"); // only patients can self-register
  const [form, setForm] = useState({ name: "", email: "", password: "" });
  const [otp, setOtp] = useState("");
  const [errors, setErrors] = useState({});
  const [serverError, setServerError] = useState("");
  const [loading, setLoading] = useState(false);
  const [cooldown, startCooldown] = useCooldown();

  if (user) return <Navigate to={ROLE_HOME[user.role] ?? "/"} replace />;

  const email = form.email.trim().toLowerCase();
  const update = (field) => (e) => setForm((f) => ({ ...f, [field]: e.target.value }));

  // Step 1 request, also used for "Resend code" (the docs say to call register again).
  async function sendCode() {
    setLoading(true);
    setServerError("");
    try {
      await register({ name: form.name.trim(), email, password: form.password });
      startCooldown(60);
      return true;
    } catch (err) {
      setServerError(errorMessage(err));
      if (err.code === "REGISTRATION_COOLDOWN") startCooldown(60);
      return false;
    } finally {
      setLoading(false);
    }
  }

  async function handleDetails(e) {
    e.preventDefault();
    const found = {
      name: validateName(form.name),
      email: validateEmail(form.email),
      password: validateNewPassword(form.password),
    };
    setErrors(found);
    if (Object.values(found).some(Boolean)) return;

    if (await sendCode()) {
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
      await verifyRegistration({ email, otp });
      // Registration does not log you in, so send them to the login page.
      navigate("/login", { state: { registeredEmail: email } });
    } catch (err) {
      setServerError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  if (step === "otp") {
    return (
      <AuthShell
        title="Check your email"
        subtitle={`If ${email} can be registered, we've sent a 6-digit code to it.`}
        footer={
          <button
            type="button"
            onClick={() => {
              setStep("details");
              setServerError("");
              setErrors({});
            }}
            className="font-medium text-primary/70 hover:underline"
          >
            Use a different email
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
          <SubmitButton loading={loading}>Verify and create account</SubmitButton>
          <button
            type="button"
            onClick={sendCode}
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
      title="Create your account"
      subtitle="Register as a patient to book tokens and track your queue."
      footer={
        <>
          Already have an account?{" "}
          <Link to="/login" className="font-medium text-primary/70 hover:underline">
            Log in
          </Link>
        </>
      }
    >
      <div className="space-y-5">
        <RoleSelector value={role} onChange={setRole} />

        {role !== "patient" ? (
          <div className="space-y-4">
            <Banner type="info">
              {role === "doctor" ? "Doctor" : "Staff"} accounts are created by the hospital
              administrator, so there is no sign-up here. Once your account is ready, log in
              with the "{role === "doctor" ? "Doctor" : "Staff"}" option.
            </Banner>
            <Link
              to="/login"
              className="block w-full rounded-xl bg-primary/70 px-6 py-3 text-center font-medium text-white shadow-md transition-colors hover:bg-primary/80"
            >
              Go to login
            </Link>
          </div>
        ) : (
          <>
            <form onSubmit={handleDetails} className="space-y-4" noValidate>
              {serverError && <Banner>{serverError}</Banner>}
              <TextField
                id="name"
                label="Full name"
                value={form.name}
                onChange={update("name")}
                error={errors.name}
                autoComplete="name"
              />
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
                autoComplete="new-password"
              />
              <SubmitButton loading={loading}>Send verification code</SubmitButton>
            </form>
            <GoogleButton />
          </>
        )}
      </div>
    </AuthShell>
  );
}