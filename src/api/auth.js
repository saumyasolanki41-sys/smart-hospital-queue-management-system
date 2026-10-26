import { request } from "./client";

// ---- Endpoints -------------------------------------------------------------

export const register = (payload) => request("/api/auth/register", { method: "POST", body: payload });
export const verifyRegistration = (payload) =>
  request("/api/auth/register/verify", { method: "POST", body: payload });
export const login = (payload) => request("/api/auth/login", { method: "POST", body: payload });
export const verifyLogin = (payload) =>
  request("/api/auth/login/verify", { method: "POST", body: payload });
export const getMe = (token) => request("/api/auth/me", { token });
export const googleLogin = (idToken) =>
  request("/api/auth/google", { method: "POST", body: { idToken } });
export const forgotPassword = (payload) =>
  request("/api/auth/forgot-password", { method: "POST", body: payload });
export const resetPassword = (payload) =>
  request("/api/auth/reset-password", { method: "POST", body: payload });

// ---- Friendly error text ---------------------------------------------------

export function errorMessage(err) {
  switch (err.code) {
    case "RATE_LIMITED":
      return "Too many attempts. Please try again in a few minutes.";
    case "REGISTRATION_COOLDOWN":
    case "LOGIN_COOLDOWN":
      return "Please wait about a minute before requesting another code.";
    case "INVALID_OR_EXPIRED_OTP":
      return "That code is incorrect or has expired.";
    case "ACCOUNT_EXISTS":
      return "An account with this email already exists. Try logging in.";
    case "INVALID_GOOGLE_TOKEN":
      return "Google sign-in failed. Please try again.";
    case "ACCOUNT_LINK_REQUIRED":
      return "This email already has a password account. Please log in with your email and password instead.";
    case "EMAIL_VERIFICATION_REQUIRED":
      return "We couldn't verify this Google account's email. Please use another sign-in method.";
    case "EMAIL_UNAVAILABLE":
      return "We couldn't send the email right now. Please try again in a few minutes.";
    default:
      return err.message || "Something went wrong. Please try again.";
  }
}

// ---- Client-side validation (mirrors the backend rules) --------------------

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateName(value) {
  const n = value.trim();
  return n.length < 2 || n.length > 100 ? "Name must be 2–100 characters." : "";
}

export function validateEmail(value) {
  const e = value.trim();
  return !EMAIL_RE.test(e) || e.length > 254 ? "Enter a valid email address." : "";
}

export function validateNewPassword(value) {
  if (value.length < 8) return "Password must be at least 8 characters.";
  if (new TextEncoder().encode(value).length > 72) return "Password is too long (max 72 bytes).";
  return "";
}

export const isValidOtp = (value) => /^\d{6}$/.test(value);

// ---- Role options on the login/register pages ------------------------------


export const ROLE_OPTIONS = [
  { value: "patient", label: "Patient", roles: ["patient"] },
  { value: "doctor", label: "Doctor", roles: ["doctor"] },
  { value: "staff", label: "Staff", roles: ["receptionist", "admin"] },
];

export const roleMatches = (selected, actualRole) =>
  ROLE_OPTIONS.find((o) => o.value === selected)?.roles.includes(actualRole) ?? false;

export const optionForRole = (actualRole) =>
  ROLE_OPTIONS.find((o) => o.roles.includes(actualRole))?.value ?? "patient";

export function roleMismatchMessage(actualRole) {
  const option = ROLE_OPTIONS.find((o) => o.roles.includes(actualRole));
  const label = option?.label ?? actualRole;
  return `This is a ${label.toLowerCase()} account. Select "${label}" to log in.`;
}