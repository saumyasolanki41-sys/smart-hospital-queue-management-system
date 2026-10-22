import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { setUnauthorizedHandler } from "../../api/client";
import { getMe } from "../../api/auth";

const AuthContext = createContext(null);


export const ROLE_HOME = {
  patient: "/home",
  doctor: "/doctor",
  receptionist: "/staff",
  admin: "/staff",
};

const STORAGE_KEY = "smart-hospital-session";

function loadStoredSession() {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const saved = JSON.parse(raw);
    if (saved?.token && saved?.user && saved.expiresAt > Date.now()) return saved;
  } catch {

  }
  return null;
}

export function AuthProvider({ children }) {
  
  const [session, setSession] = useState(loadStoredSession);
  const restoredToken = useRef(session?.token ?? null);

  const signIn = useCallback((data) => {
    setSession({
      token: data.accessToken,
      user: data.user,
      expiresAt: Date.now() + data.expiresIn * 1000,
    });
  }, []);

  const signOut = useCallback(() => setSession(null), []);

  useEffect(() => {
    try {
      if (session) sessionStorage.setItem(STORAGE_KEY, JSON.stringify(session));
      else sessionStorage.removeItem(STORAGE_KEY);
    } catch {
      
    }
  }, [session]);

  
  useEffect(() => {
    const token = restoredToken.current;
    if (!token) return;
    let ignore = false;
    getMe(token)
      .then(({ user }) => {
        if (!ignore) setSession((prev) => (prev && prev.token === token ? { ...prev, user } : prev));
      })
      .catch(() => {});
    return () => {
      ignore = true;
    };
  }, []);

  useEffect(() => {
    if (!session) return;
    const timer = setTimeout(() => setSession(null), Math.max(session.expiresAt - Date.now(), 0));
    return () => clearTimeout(timer);
  }, [session]);

  useEffect(() => {
    setUnauthorizedHandler(signOut);
    return () => setUnauthorizedHandler(null);
  }, [signOut]);

  const value = useMemo(
    () => ({ user: session?.user ?? null, token: session?.token ?? null, signIn, signOut }),
    [session, signIn, signOut]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside <AuthProvider>");
  return ctx;
}