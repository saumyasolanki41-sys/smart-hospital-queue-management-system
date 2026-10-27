import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Briefcase, Clock, Wallet, Info } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import DoctorCard from "../components/hospital/DoctorCard";
import { useAuth } from "../components/context/AuthContext";
import { getDoctor, getDoctors } from "../api/hospital";
import { useOwnDoctorId } from "../hooks/useOwnDoctorId";
import { joinQueue, getMyTokens } from "../api/queue";

const inr = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

function initials(name) {
  const parts = name.replace(/^dr\.?\s+/i, "").trim().split(/\s+/);
  return ((parts[0]?.[0] ?? "") + (parts[1]?.[0] ?? "")).toUpperCase() || "D";
}

function Stat({ icon: Icon, label, value }) {
  return (
    <div className="rounded-2xl bg-white/90 p-5 shadow-md">
      <div className="flex items-center gap-2 text-sm text-slate-600">
        <Icon className="h-4 w-4 text-primary/70" />
        {label}
      </div>
      <p className="mt-2 text-2xl font-bold text-slate-900">{value}</p>
    </div>
  );
}

function Profile({ doctorId }) {
  const { user, token: accessToken } = useAuth();
  const navigate = useNavigate();
  const { doctorId: ownDoctorId } = useOwnDoctorId();
  const isOwn = ownDoctorId === doctorId; 

  const [doctor, setDoctor] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null); 
  const [related, setRelated] = useState([]);
  const [joining, setJoining] = useState(false);
  const [notice, setNotice] = useState(null); 
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let ignore = false;
    getDoctor(doctorId)
      .then((d) => !ignore && setDoctor(d))
      .catch((err) => {
        if (!ignore) {
          setError({
            message: err.message,
            notFound: err.code === "DOCTOR_NOT_FOUND" || err.code === "VALIDATION_ERROR",
          });
        }
      })
      .finally(() => !ignore && setLoading(false));
    return () => {
      ignore = true;
    };
  }, [doctorId, reloadKey]);

  // Other doctors in the same department (nice to have, so failures are ignored).
  const departmentId = doctor?.department?._id;
  useEffect(() => {
    if (!departmentId) return;
    let ignore = false;
    getDoctors({ departmentId, limit: 5 })
      .then((list) => !ignore && setRelated(list.filter((d) => d._id !== doctorId).slice(0, 3)))
      .catch(() => {});
    return () => {
      ignore = true;
    };
  }, [departmentId, doctorId]);

  async function handleJoin() {
    if (!user) {
      navigate("/login", { state: { from: `/doctors/${doctorId}` } }); // log in, then come back here
      return;
    }

    setNotice(null);
    setJoining(true);
    try {
      const joined = await joinQueue(accessToken, doctor._id);
      navigate(`/queue/${joined._id}`);
    } catch (err) {
      if (err.code === "UNAUTHORIZED") return; 
      if (err.code === "ALREADY_IN_QUEUE") {
        
        try {
          const mine = await getMyTokens(accessToken);
          const existing = mine.find(
            (t) => t.doctor?._id === doctor._id && (t.status === "waiting" || t.status === "called")
          );
          if (existing) {
            navigate(`/queue/${existing._id}`);
            return;
          }
        } catch {
          
        }
        setNotice({ tone: "info", text: "You're already in this doctor's queue today.", linkTo: "/queue" });
      } else if (err.code === "QUEUE_CONFLICT") {
        
        setNotice({
          tone: "error",
          text: "We couldn't confirm your booking. Please check your queue before trying again.",
          linkTo: "/queue",
        });
      } else if (err.code === "DOCTOR_UNAVAILABLE") {
        setNotice({ tone: "error", text: "This doctor isn't taking new patients right now." });
      } else {
        setNotice({ tone: "error", text: err.message });
      }
    } finally {
      setJoining(false);
    }
  }

  let content;
  if (loading) {
    content = (
      <div className="space-y-6">
        <div className="h-40 animate-pulse rounded-3xl bg-white/70" />
        <div className="grid gap-4 sm:grid-cols-3">
          {[0, 1, 2].map((i) => (
            <div key={i} className="h-24 animate-pulse rounded-2xl bg-white/70" />
          ))}
        </div>
      </div>
    );
  } else if (error || !doctor) {
    content = (
      <div role="alert" className="rounded-2xl bg-white/90 p-8 text-center shadow-md">
        <p className="text-slate-700">
          {error?.notFound ? "We couldn't find this doctor." : `Couldn't load this profile. ${error?.message ?? ""}`}
        </p>
        <div className="mt-4 flex flex-wrap justify-center gap-3">
          {!error?.notFound && (
            <button
              type="button"
              onClick={() => {
                setLoading(true);
                setError(null);
                setReloadKey((k) => k + 1);
              }}
              className="rounded-xl border border-primary/60 px-5 py-2 text-sm font-medium text-primary/70 hover:bg-primary/5"
            >
              Retry
            </button>
          )}
          <Link
            to="/departments"
            className="rounded-xl bg-primary/70 px-5 py-2 text-sm font-medium text-white hover:bg-primary/80"
          >
            Browse doctors
          </Link>
        </div>
      </div>
    );
  } else {
    const canJoin = !user || user.role === "patient"; 
    content = (
      <>
        {isOwn && (
          <div
            role="note"
            className="mb-6 flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-primary/5 p-4 text-sm text-primary/90"
          >
            <span className="flex items-start gap-2">
              <Info className="mt-0.5 h-4 w-4 shrink-0" />
              This is your public profile, the page patients see. An administrator manages these details.
            </span>
            <Link to="/doctor" className="font-medium underline">
              Open my queue →
            </Link>
          </div>
        )}

        {/* Header */}
        <section className="rounded-3xl bg-white/95 p-6 shadow-xl sm:p-8">
          <div className="flex flex-wrap items-start gap-5">
            <span className="flex h-20 w-20 shrink-0 items-center justify-center rounded-full bg-secondary/10 text-2xl font-bold text-primary/80">
              {initials(doctor.name)}
            </span>
            <div className="min-w-0 flex-1">
              <h1 className="text-3xl font-bold text-slate-900">{doctor.name}</h1>
              <p className="mt-1 text-lg text-slate-600">{doctor.specialization}</p>
              {doctor.department?.name && (
                <Link
                  to={`/departments?department=${doctor.department._id}`}
                  className="mt-2 inline-block rounded-full bg-primary/5 px-3 py-1 text-sm font-medium text-primary/80 hover:bg-primary/10"
                >
                  {doctor.department.name}
                </Link>
              )}
            </div>
            <span
              className={`shrink-0 rounded-full px-3 py-1 text-sm font-medium ${
                doctor.isAvailable ? "bg-green-100 text-green-800" : "bg-slate-100 text-slate-600"
              }`}
            >
              {doctor.isAvailable ? "Accepting patients" : "Not accepting patients"}
            </span>
          </div>
        </section>

        {/* Key facts */}
        <section aria-label="Details" className="mt-6 grid gap-4 sm:grid-cols-3">
          <Stat
            icon={Briefcase}
            label="Experience"
            value={`${doctor.experienceYears} ${doctor.experienceYears === 1 ? "year" : "years"}`}
          />
          <Stat
            icon={Wallet}
            label="Consultation fee"
            value={doctor.consultationFee > 0 ? inr.format(doctor.consultationFee) : "Not listed"}
          />
          <Stat
            icon={Clock}
            label="Time per patient"
            value={doctor.averageConsultationMinutes ? `About ${doctor.averageConsultationMinutes} min` : "Not listed"}
          />
        </section>

        {/* Join the queue */}
        <section aria-label="Join the queue" className="mt-6 rounded-3xl bg-white/95 p-6 shadow-xl sm:p-8">
          <h2 className="text-xl font-semibold text-slate-900">See this doctor today</h2>
          <p className="mt-2 max-w-2xl text-slate-600">
            Join today's queue to get a token number. You'll then see how many patients are ahead of you and an
            estimated wait. Queues are for the same day, so there are no appointment slots to book.
          </p>

          {notice && (
            <div
              role={notice.tone === "error" ? "alert" : "status"}
              className={`mt-4 flex items-start gap-2 rounded-xl p-3 text-sm ${
                notice.tone === "error" ? "bg-red-50 text-red-700" : "bg-secondary/5 text-primary/80"
              }`}
            >
              <Info className="mt-0.5 h-4 w-4 shrink-0" />
              <span>
                {notice.text}
                {notice.linkTo && (
                  <>
                    {" "}
                    <Link to={notice.linkTo} className="font-medium underline">
                      View My Queue
                    </Link>
                  </>
                )}
              </span>
            </div>
          )}

          <div className="mt-5">
            {canJoin ? (
              <button
                type="button"
                onClick={handleJoin}
                disabled={!doctor.isAvailable || joining}
                className="rounded-xl bg-primary/70 px-7 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80 disabled:cursor-not-allowed disabled:bg-slate-200 disabled:text-slate-500 disabled:shadow-none"
              >
                {joining
                  ? "Joining…"
                  : !doctor.isAvailable
                  ? "Not taking new patients"
                  : user
                  ? "Join queue"
                  : "Log in to join the queue"}
              </button>
            ) : (
              <p className="text-sm text-slate-500">Only patient accounts can join a queue.</p>
            )}
          </div>

          <p className="mt-5 flex items-start gap-2 text-xs text-slate-500">
            <Info className="mt-0.5 h-3.5 w-3.5 shrink-0" />
            "Accepting patients" means new queue bookings are open. It doesn't promise the doctor is free right
            now. The fee is for information only and nothing is paid on this site.
          </p>
        </section>

        {/* More doctors in the department */}
        {related.length > 0 && (
          <section aria-label="More doctors" className="mt-10">
            <h2 className="mb-4 text-xl font-semibold text-slate-900">
              More in {doctor.department?.name ?? "this department"}
            </h2>
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {related.map((d) => (
                <Link key={d._id} to={`/doctors/${d._id}`} className="block rounded-3xl transition hover:shadow-lg">
                  <DoctorCard doctor={d} showJoin={false} link={false} />
                </Link>
              ))}
            </div>
          </section>
        )}
      </>
    );
  }

  return (
    <div className={`min-h-screen ${user ? "bg-transparent" : "bg-gradient-to-br from-secondary/5 via-accent/5 to-white"}`}>
      <Navbar />
      <main className="mx-auto max-w-4xl px-6 pb-20 pt-6">
        <Link
          to={doctor?.department?._id ? `/departments?department=${doctor.department._id}` : "/departments"}
          className="mb-5 inline-block text-sm font-medium text-primary/70 hover:underline"
        >
          ← Departments &amp; doctors
        </Link>
        {content}
      </main>
    </div>
  );
}

export default function DoctorProfile() {
  const { doctorId } = useParams();
  
  return <Profile key={doctorId} doctorId={doctorId} />;
}