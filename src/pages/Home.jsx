import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Ticket, Stethoscope, Info, Users, Hourglass, ArrowRight } from "lucide-react";
import Navbar from "../components/layout/Navbar";
import StatusBadge from "../components/queue/StatusBadge";
import DepartmentCard from "../components/hospital/DepartmentCard";
import Pagination from "../components/common/Pagination";
import { useAuth } from "../components/context/AuthContext";
import { getMyTokens, getTokenStatus } from "../api/queue";
import { getDepartments } from "../api/hospital";
import { formatWait } from "../utils/time";

const REFRESH_MS = 15000;
const DEPARTMENTS_PER_PAGE = 8; 

function greeting() {
  const hour = new Date().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 17) return "Good afternoon";
  return "Good evening";
}

function MiniStat({ icon: Icon, label, value }) {
  return (
    <div className="rounded-2xl bg-secondary/5 p-4">
      <div className="flex items-center gap-2 text-sm text-slate-600">
        <Icon className="h-4 w-4 text-primary/70" />
        {label}
      </div>
      <p className="mt-1 text-xl font-bold text-slate-900">{value}</p>
    </div>
  );
}

function ActiveTokenCard({ token, detail }) {
  const est = detail?.estimatedWaitMinutes;
  const waitText = formatWait(est);

  return (
    <article className="rounded-3xl bg-white/95 p-6 shadow-xl">
      <div className="flex items-start justify-between gap-4">
        <div className="flex min-w-0 items-center gap-4">
          <span className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-primary/5 text-2xl font-bold text-primary/80">
            #{token.tokenNumber}
          </span>
          <div className="min-w-0">
            <p className="truncate text-lg font-semibold text-slate-900">
              {token.doctor?.name ?? "Doctor no longer listed"}
            </p>
            <p className="truncate text-sm text-slate-500">{token.doctor?.specialization}</p>
          </div>
        </div>
        <StatusBadge status={token.status} />
      </div>

      {token.status === "called" ? (
        <p className="mt-5 rounded-2xl bg-primary/5 p-4 text-primary/90">
          You've been called. Please go to the doctor now.
        </p>
      ) : (
        detail && (
          <>
            <div className="mt-5 grid gap-4 sm:grid-cols-2">
              <MiniStat icon={Users} label="Patients ahead" value={detail.peopleAhead ?? "—"} />
              <MiniStat icon={Hourglass} label="Estimated wait" value={waitText} />
            </div>
            <p className="mt-3 text-xs text-slate-500">
              An estimate, not an exact appointment time.
            </p>
          </>
        )
      )}

      <Link
        to={`/queue/${token._id}`}
        className="mt-5 inline-flex items-center gap-2 text-sm font-medium text-primary/70 hover:underline"
      >
        View details
        <ArrowRight className="h-4 w-4" />
      </Link>
    </article>
  );
}

function ActionTile({ to, icon: Icon, title, text }) {
  return (
    <Link
      to={to}
      className="flex items-center gap-4 rounded-2xl bg-white/90 p-4 shadow-md transition hover:shadow-lg"
    >
      <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary/5 text-primary/70">
        <Icon className="h-5 w-5" />
      </span>
      <span className="min-w-0">
        <span className="block font-semibold text-slate-900">{title}</span>
        <span className="block text-sm text-slate-500">{text}</span>
      </span>
    </Link>
  );
}

export default function Home() {
  const { user, token: accessToken, signOut } = useAuth();
  const navigate = useNavigate();

  const [tokens, setTokens] = useState([]); 
  const [details, setDetails] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [departments, setDepartments] = useState([]);
  const [deptPage, setDeptPage] = useState(1);

  const load = useCallback(async () => {
    try {
      const list = await getMyTokens(accessToken);
      const live = list.filter((t) => t.status === "waiting" || t.status === "called");
      const liveDetails = await Promise.all(
        live.map((t) => getTokenStatus(accessToken, t._id).catch(() => null))
      );
      setTokens(list);
      setDetails(Object.fromEntries(live.map((t, i) => [t._id, liveDetails[i]])));
      setError("");
    } catch (err) {
      if (err.code === "UNAUTHORIZED") {
        signOut();
        return;
      }
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [accessToken, signOut]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    let ignore = false;
    getDepartments()
      .then((list) => !ignore && setDepartments(list))
      .catch(() => {});
    return () => {
      ignore = true;
    };
  }, []);

  const active = tokens.filter((t) => t.status === "waiting" || t.status === "called");
  const earlier = tokens.filter((t) => t.status !== "waiting" && t.status !== "called");

  const totalDeptPages = Math.max(1, Math.ceil(departments.length / DEPARTMENTS_PER_PAGE));
  const currentDeptPage = Math.min(deptPage, totalDeptPages);
  const deptStart = (currentDeptPage - 1) * DEPARTMENTS_PER_PAGE;
  const visibleDepartments = departments.slice(deptStart, deptStart + DEPARTMENTS_PER_PAGE);

  const hasActive = active.length > 0;
  useEffect(() => {
    if (!hasActive) return;
    const timer = setInterval(load, REFRESH_MS);
    return () => clearInterval(timer);
  }, [hasActive, load]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-sky-500/5 via-accent-500/5 to-white">
      <Navbar />

      <main className="mx-auto max-w-6xl px-6 pb-20 pt-6">
        <header className="mb-8">
          <p className="mb-1 text-base font-medium text-primary/70">{greeting()}</p>
          <h1 className="text-3xl font-bold text-slate-900 sm:text-4xl">
            Hi, {user.name.split(" ")[0]}
          </h1>
          <p className="mt-2 text-slate-600">Here's where your queue stands today.</p>
        </header>

        <div className="grid gap-8 lg:grid-cols-3">
          {/* Today's queue */}
          <section aria-label="Your queue today" className="space-y-5 lg:col-span-2">
            {loading ? (
              <div className="h-48 animate-pulse rounded-3xl bg-white/70" />
            ) : error ? (
              <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-red-50 p-5 text-red-700">
                <span>Couldn't load your queue. {error}</span>
                <button
                  type="button"
                  onClick={() => {
                    setLoading(true);
                    load();
                  }}
                  className="rounded-lg border border-red-300 px-4 py-1.5 text-sm font-medium hover:bg-red-100"
                >
                  Retry
                </button>
              </div>
            ) : active.length === 0 ? (
              <div className="rounded-3xl bg-white/95 p-8 text-center shadow-xl">
                <span className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/5 text-primary/70">
                  <Ticket className="h-7 w-7" />
                </span>
                <h2 className="text-xl font-semibold text-slate-900">You're not in a queue right now</h2>
                <p className="mx-auto mt-2 max-w-md text-slate-600">
                  Pick a department, choose a doctor and join their queue. You'll see your place and
                  estimated wait here.
                </p>
                <Link
                  to="/departments"
                  className="mt-6 inline-block rounded-xl bg-primary/70 px-7 py-3 font-medium text-white shadow-md transition-colors hover:bg-primary/80"
                >
                  Find a doctor
                </Link>
              </div>
            ) : (
              active.map((t) => <ActiveTokenCard key={t._id} token={t} detail={details[t._id]} />)
            )}

            {earlier.length > 0 && (
              <div>
                <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">
                  Earlier today
                </h2>
                <ul className="space-y-2">
                  {earlier.map((t) => (
                    <li key={t._id}>
                      <Link
                        to={`/queue/${t._id}`}
                        className="flex items-center gap-3 rounded-2xl bg-white/80 p-3 text-sm transition hover:bg-white"
                      >
                        <span className="font-semibold text-slate-700">#{t.tokenNumber}</span>
                        <span className="min-w-0 flex-1 truncate text-slate-600">
                          {t.doctor?.name ?? "Doctor no longer listed"}
                        </span>
                        <StatusBadge status={t.status} />
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </section>

          {/* Quick actions */}
          <aside aria-label="Quick actions" className="space-y-4">
            <ActionTile
              to="/departments"
              icon={Stethoscope}
              title="Find a doctor"
              text="Browse departments and join a queue"
            />
            <ActionTile to="/queue" icon={Ticket} title="My queue" text="All of today's tokens" />
            <ActionTile
              to="/about#how-it-works"
              icon={Info}
              title="How it works"
              text="Tokens, queues and wait times"
            />
          </aside>
        </div>

        {departments.length > 0 && (
          <section aria-label="Departments" className="mt-12">
            <div className="mb-4 flex items-baseline justify-between gap-4">
              <h2 className="text-xl font-semibold text-slate-900">Browse by department</h2>
              <Link to="/departments" className="text-sm font-medium text-primary/70 hover:underline">
                All doctors →
              </Link>
            </div>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {visibleDepartments.map((d) => (
                <DepartmentCard
                  key={d._id}
                  name={d.name}
                  description={d.description}
                  selected={false}
                  onClick={() => navigate(`/departments?department=${d._id}`)}
                />
              ))}
            </div>

            {totalDeptPages > 1 && (
              <div className="mt-6 flex flex-col items-center gap-2">
                <Pagination
                  page={currentDeptPage}
                  totalPages={totalDeptPages}
                  onChange={setDeptPage}
                  label="Department pages"
                />
                <p className="text-sm text-slate-500">
                  Showing {deptStart + 1}–{Math.min(deptStart + DEPARTMENTS_PER_PAGE, departments.length)} of{" "}
                  {departments.length} departments
                </p>
              </div>
            )}
          </section>
        )}
      </main>
    </div>
  );
}