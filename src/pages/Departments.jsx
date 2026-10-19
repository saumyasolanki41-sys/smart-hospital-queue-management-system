// src/pages/Departments.jsx — departments and doctors on a single public page.
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Search, Info } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import DepartmentCard from "../components/hospital/DepartmentCard";
import DoctorCard from "../components/hospital/DoctorCard";
import { useAuth } from "../components/context/AuthContext";
import { getDepartments, getDoctors } from "../api/hospital";
import { joinQueue, getMyTokens } from "../api/queue";

const PAGE_SIZE = 12;

function Skeleton({ className }) {
  return <div className={`animate-pulse rounded-2xl bg-white/70 ${className}`} />;
}

function ErrorBox({ message, onRetry }) {
  return (
    <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-red-50 p-4 text-sm text-red-700">
      <span>{message}</span>
      <button
        type="button"
        onClick={onRetry}
        className="rounded-lg border border-red-300 px-4 py-1.5 font-medium hover:bg-red-100"
      >
        Retry
      </button>
    </div>
  );
}

export default function Departments() {
  const { user, token: accessToken, signOut } = useAuth();
  const navigate = useNavigate();

  // Departments
  const [departments, setDepartments] = useState([]);
  const [deptLoading, setDeptLoading] = useState(true);
  const [deptError, setDeptError] = useState("");
  const [deptKey, setDeptKey] = useState(0); // bump to retry

  // Doctors + filters
  const [selected, setSelected] = useState(null); // department _id, or null for "all"
  const [availableOnly, setAvailableOnly] = useState(false);
  const [search, setSearch] = useState("");
  const [doctors, setDoctors] = useState([]);
  const [docLoading, setDocLoading] = useState(true);
  const [docError, setDocError] = useState("");
  const [docKey, setDocKey] = useState(0); // bump to retry
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [moreLoading, setMoreLoading] = useState(false);
  const [moreError, setMoreError] = useState("");

  const [notice, setNotice] = useState(null); // { tone: "error" | "info", text, linkTo? }
  const [joiningId, setJoiningId] = useState(null); // doctor being joined right now

  useEffect(() => {
    let ignore = false;
    getDepartments()
      .then((list) => !ignore && setDepartments(list))
      .catch((err) => !ignore && setDeptError(err.message))
      .finally(() => !ignore && setDeptLoading(false));
    return () => {
      ignore = true;
    };
  }, [deptKey]);

  useEffect(() => {
    let ignore = false;
    getDoctors({ departmentId: selected, availableOnly, page: 1, limit: PAGE_SIZE })
      .then((list) => {
        if (ignore) return;
        setDoctors(list);
        setPage(1);
        setHasMore(list.length === PAGE_SIZE);
      })
      .catch((err) => !ignore && setDocError(err.message))
      .finally(() => !ignore && setDocLoading(false));
    return () => {
      ignore = true;
    };
  }, [selected, availableOnly, docKey]);

  function startDoctorLoad() {
    setDocLoading(true);
    setDocError("");
    setMoreError("");
  }

  function chooseDepartment(id) {
    if (id === selected) return;
    startDoctorLoad();
    setSelected(id);
  }

  function toggleAvailable(e) {
    startDoctorLoad();
    setAvailableOnly(e.target.checked);
  }

  function retryDepartments() {
    setDeptLoading(true);
    setDeptError("");
    setDeptKey((k) => k + 1);
  }

  function retryDoctors() {
    startDoctorLoad();
    setDocKey((k) => k + 1);
  }

  async function loadMore() {
    setMoreLoading(true);
    setMoreError("");
    try {
      const next = page + 1;
      const list = await getDoctors({ departmentId: selected, availableOnly, page: next, limit: PAGE_SIZE });
      setDoctors((prev) => [...prev, ...list]);
      setPage(next);
      setHasMore(list.length === PAGE_SIZE);
    } catch (err) {
      setMoreError(err.message);
    } finally {
      setMoreLoading(false);
    }
  }

  async function handleJoin(doctor) {
    if (!user) {
      // Log in first, then come back to this page.
      navigate("/login", { state: { from: "/departments" } });
      return;
    }

    setNotice(null);
    setJoiningId(doctor._id);
    try {
      const joined = await joinQueue(accessToken, doctor._id);
      navigate(`/queue/${joined._id}`);
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut(); // session expired
        return;
      }
      if (err.code === "ALREADY_IN_QUEUE") {
        // Take them to the token they already have with this doctor.
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
          // fall through to the message below
        }
        setNotice({ tone: "info", text: `You're already in ${doctor.name}'s queue today.`, linkTo: "/queue" });
      } else if (err.code === "QUEUE_CONFLICT") {
        // Per the API docs: check your tokens before trying again.
        setNotice({
          tone: "error",
          text: "We couldn't confirm your booking. Please check your queue before trying again.",
          linkTo: "/queue",
        });
      } else if (err.code === "DOCTOR_UNAVAILABLE") {
        setNotice({ tone: "error", text: `${doctor.name} isn't taking new patients right now.` });
      } else {
        setNotice({ tone: "error", text: err.message });
      }
    } finally {
      setJoiningId(null);
    }
  }

  const query = search.trim().toLowerCase();
  const visibleDoctors = query
    ? doctors.filter(
        (d) => d.name.toLowerCase().includes(query) || d.specialization.toLowerCase().includes(query)
      )
    : doctors;

  const selectedName = departments.find((d) => d._id === selected)?.name;
  const showJoin = !user || user.role === "patient"; // doctors and staff don't join queues

  let emptyMessage = "No doctors are listed yet.";
  if (query) emptyMessage = "No doctors match your search.";
  else if (availableOnly) emptyMessage = "No doctors are available right now. Try turning off the filter.";

  return (
    <div className="min-h-screen bg-gradient-to-br from-sky-50 via-cyan-50 to-white">
      <Navbar />

      <main className="mx-auto max-w-6xl px-6 pb-20 pt-6">
        <header className="mb-8">
          <p className="mb-2 text-base font-medium text-teal-700">Find the right care</p>
          <h1 className="text-3xl font-bold text-slate-900 sm:text-4xl">Departments &amp; Doctors</h1>
          <p className="mt-3 max-w-2xl text-slate-600">
            Pick a department, choose a doctor, and join their queue without waiting at the hospital.
          </p>
        </header>

        {notice && (
          <div
            role={notice.tone === "error" ? "alert" : "status"}
            className={`mb-6 flex items-start gap-2 rounded-xl p-3 text-sm ${
              notice.tone === "error" ? "bg-red-50 text-red-700" : "bg-sky-50 text-sky-800"
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

        {/* Departments */}
        <section aria-label="Departments" className="mb-10">
          {deptError ? (
            <ErrorBox message={`Couldn't load departments. ${deptError}`} onRetry={retryDepartments} />
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {deptLoading ? (
                Array.from({ length: 4 }, (_, i) => <Skeleton key={i} className="h-32" />)
              ) : (
                <>
                  <DepartmentCard
                    all
                    name="All doctors"
                    description="Browse every department"
                    selected={selected === null}
                    onClick={() => chooseDepartment(null)}
                  />
                  {departments.map((d) => (
                    <DepartmentCard
                      key={d._id}
                      name={d.name}
                      description={d.description}
                      selected={selected === d._id}
                      onClick={() => chooseDepartment(d._id)}
                    />
                  ))}
                </>
              )}
            </div>
          )}
        </section>

        {/* Doctors */}
        <section aria-label="Doctors">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-4">
            <h2 className="text-xl font-semibold text-slate-900">
              {selectedName ? `${selectedName} doctors` : "All doctors"}
            </h2>
            <div className="flex flex-wrap items-center gap-4">
              <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-700">
                <input
                  type="checkbox"
                  checked={availableOnly}
                  onChange={toggleAvailable}
                  className="h-4 w-4 accent-teal-700"
                />
                Available only
              </label>
              <div className="relative">
                <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="search"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search by name or specialty"
                  aria-label="Search doctors"
                  className="w-64 max-w-full rounded-xl border border-slate-200 bg-white py-2 pl-9 pr-3 text-sm outline-none focus:border-teal-600 focus:ring-2 focus:ring-teal-500/40"
                />
              </div>
            </div>
          </div>

          {docError ? (
            <ErrorBox message={`Couldn't load doctors. ${docError}`} onRetry={retryDoctors} />
          ) : docLoading ? (
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {Array.from({ length: 6 }, (_, i) => (
                <Skeleton key={i} className="h-56" />
              ))}
            </div>
          ) : visibleDoctors.length === 0 ? (
            <p className="rounded-2xl bg-white/80 p-8 text-center text-slate-600">{emptyMessage}</p>
          ) : (
            <>
              <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                {visibleDoctors.map((doctor) => (
                  <DoctorCard
                    key={doctor._id}
                    doctor={doctor}
                    showJoin={showJoin}
                    onJoin={handleJoin}
                    joining={joiningId === doctor._id}
                    busy={joiningId !== null}
                  />
                ))}
              </div>

              {hasMore && (
                <div className="mt-8 text-center">
                  <button
                    type="button"
                    onClick={loadMore}
                    disabled={moreLoading}
                    className="rounded-xl border border-teal-600 px-6 py-2.5 text-sm font-medium text-teal-700 hover:bg-teal-50 disabled:opacity-60"
                  >
                    {moreLoading ? "Loading…" : "Load more doctors"}
                  </button>
                  {moreError && <p className="mt-2 text-sm text-red-600">{moreError}</p>}
                </div>
              )}
            </>
          )}
        </section>
      </main>
    </div>
  );
}