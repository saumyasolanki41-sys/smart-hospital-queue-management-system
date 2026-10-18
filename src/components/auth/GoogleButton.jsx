// src/components/auth/GoogleButton.jsx
import { useState } from "react";
import { GoogleLogin } from "@react-oauth/google";
import { googleLogin, errorMessage, roleMatches, roleMismatchMessage } from "../../api/auth";
import { useAuth } from "../context/AuthContext";
import { Banner } from "./AuthParts";

// role (optional): the option selected on the page. If the account has a different role,
// the sign-in is rejected. onWrongRole(actualRole) lets the page switch to the right option.
export default function GoogleButton({ role, onWrongRole }) {
  const { signIn } = useAuth();
  const [error, setError] = useState("");

  // No client ID configured: hide the button instead of breaking the page.
  if (!import.meta.env.VITE_GOOGLE_CLIENT_ID) return null;

  async function handleSuccess(response) {
    setError("");
    if (!response.credential) {
      setError("Google sign-in failed. Please try again.");
      return;
    }
    try {
      // The backend verifies the Google ID token and returns our own access token.
      const data = await googleLogin(response.credential);
      if (role && !roleMatches(role, data.user.role)) {
        setError(roleMismatchMessage(data.user.role));
        onWrongRole?.(data.user.role);
        return;
      }
      signIn(data); // the page's redirect takes over once the user is set
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mt-6">
      <div className="mb-4 flex items-center gap-3 text-xs uppercase tracking-wide text-slate-400">
        <span className="h-px flex-1 bg-slate-200" />
        or
        <span className="h-px flex-1 bg-slate-200" />
      </div>

      {error && (
        <div className="mb-3">
          <Banner>{error}</Banner>
        </div>
      )}

      <div className="flex justify-center">
        <GoogleLogin
          onSuccess={handleSuccess}
          onError={() => setError("Google sign-in was cancelled or failed. Please try again.")}
          text="continue_with"
          shape="pill"
          width={320}
        />
      </div>
    </div>
  );
}