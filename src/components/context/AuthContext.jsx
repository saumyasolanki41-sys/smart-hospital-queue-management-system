import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

const AuthContext = createContext(null);


export const ROLE_HOME = {
  patient: "/home",
  doctor: "/doctor",
  receptionist: "/staff",
  admin: "/staff",
};

export function AuthProvider({ children }) {
  
  const [session, setSession] = useState(null);

  const signIn = useCallback((data) => {
    setSession({
      token: data.accessToken,
      user: data.user,
      expiresAt: Date.now() + data.expiresIn * 1000,
    });
  }, []);

  const signOut = useCallback(() => setSession(null), []);

  useEffect(() => {
    if (!session) return;
    const timer = setTimeout(() => setSession(null), Math.max(session.expiresAt - Date.now(), 0));
    return () => clearTimeout(timer);
  }, [session]);

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