import { useEffect, useState } from "react";
import { useAuth } from "../components/context/AuthContext";
import { getDoctors } from "../api/hospital";
import { getDoctorQueue } from "../api/staff";

const NONE = "none"; 
const key = (userId) => `smart-hospital-doctor-${userId}`;

function readCache(userId) {
  try {
    return sessionStorage.getItem(key(userId));
  } catch {
    return null;
  }
}

function writeCache(userId, value) {
  try {
    sessionStorage.setItem(key(userId), value);
  } catch {
    
  }
}

export function useOwnDoctorId() {
  const { user, token } = useAuth();
  const userId = user?.role === "doctor" ? user.id : null;

  const [result, setResult] = useState(() => {
    const cached = userId ? readCache(userId) : null;
    return { doctorId: cached && cached !== NONE ? cached : null, searched: cached !== null };
  });

  const needsSearch = userId !== null && !result.searched;

  useEffect(() => {
    if (!needsSearch) return;
    let ignore = false;

    async function search() {
      try {
        const list = await getDoctors({ limit: 50 });
        let own = null;
        for (const doctor of list) {
          if (ignore) return;
          try {
            await getDoctorQueue(token, doctor._id, { limit: 1 });
            own = doctor._id;
            break;
          } catch (err) {
            if (err.status !== 403) throw err; 
          }
        }
        writeCache(userId, own ?? NONE);
        if (!ignore) setResult({ doctorId: own, searched: true });
      } catch {
        
      }
    }

    search();
    return () => {
      ignore = true;
    };
  }, [needsSearch, userId, token]);

  return { doctorId: result.doctorId };
}