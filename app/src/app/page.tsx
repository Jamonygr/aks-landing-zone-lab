import { getLabJournal, getLabModules, getLabOverview } from '@/lib/lab';
import { PAGES_PER_MODULE, TOTAL_MODULES, TOTAL_WIKI_PAGES } from '@/lib/wiki';

export const dynamic = 'force-dynamic';

function formatDate(value: Date): string {
  return value.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default async function Home() {
  const [overview, modules, journal] = await Promise.all([
    getLabOverview(),
    getLabModules(),
    getLabJournal(6),
  ]);

  const nextActions = modules
    .filter((module) => module.status !== 'completed')
    .slice(0, 3);

  return (
    <div className="mx-auto max-w-7xl px-4 pb-16 sm:px-6 lg:px-8">
      <section className="grid gap-8 pb-10 pt-14 lg:grid-cols-[1.05fr_0.95fr]">
        <div className="fade-in-up synth-hero rounded-3xl p-6 sm:p-8">
          <p className="mono-label synth-chip mb-4 inline-flex rounded-full px-3 py-1 text-xs font-medium uppercase tracking-[0.14em]">
            AKS Lab Web App
          </p>
          <h1 className="max-w-3xl text-4xl font-semibold leading-tight tracking-tight text-slate-900 sm:text-5xl">
            Full lab operations app for your AKS landing zone.
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-slate-600">
            This app is not just a UI. It has backend routes, mutable lab state, and operational journaling so you can
            run the lab like a platform team.
          </p>
          <div className="mt-4 grid max-w-2xl gap-3 sm:grid-cols-2">
            <div className="rounded-xl border border-sky-200 bg-sky-50/80 p-3">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-sky-800">Wiki Total Pages</p>
              <p className="mt-1 text-2xl font-semibold text-slate-900">{TOTAL_WIKI_PAGES}</p>
              <p className="mt-1 text-xs text-slate-600">Full runbook page count now live</p>
            </div>
            <div className="rounded-xl border border-slate-300 bg-white/80 p-3">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Lab Modules</p>
              <p className="mt-1 text-2xl font-semibold text-slate-900">{TOTAL_MODULES}</p>
              <p className="mt-1 text-xs text-slate-600">{PAGES_PER_MODULE} pages per module</p>
            </div>
          </div>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <a
              href="/labs"
              className="synth-btn-primary rounded-xl px-5 py-3 text-sm font-semibold transition"
            >
              Open Module Tracker
            </a>
            <a
              href="/journal"
              className="synth-btn-secondary rounded-xl px-5 py-3 text-sm font-semibold transition"
            >
              Open Operations Journal
            </a>
            <a
              href={`/labs/${TOTAL_WIKI_PAGES}`}
              className="synth-btn-secondary rounded-xl px-5 py-3 text-sm font-semibold transition"
            >
              Jump to Module Runbook Page {TOTAL_WIKI_PAGES}
            </a>
          </div>
        </div>

        <div className="fade-in-up-delayed panel rounded-3xl p-6 shadow-xl shadow-slate-200/60 sm:p-7">
          <p className="mono-label text-xs font-medium uppercase tracking-[0.16em] text-slate-500">Live Overview</p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Modules</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">
                {overview.completedModules}/{overview.totalModules}
              </p>
              <p className="mt-1 text-xs text-slate-500">Shows delivery momentum across the full lab workflow.</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Checkpoints</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">
                {overview.completedCheckpoints}/{overview.totalCheckpoints}
              </p>
              <p className="mt-1 text-xs text-slate-500">Verifies critical controls are actually validated, not assumed.</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Blocked</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">{overview.blockedModules}</p>
              <p className="mt-1 text-xs text-slate-500">Highlights risk concentration so you can unblock the right areas first.</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Completion</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">{overview.completionPercent}%</p>
              <p className="mt-1 text-xs text-slate-500">Tracks overall readiness before promotion or handoff decisions.</p>
            </div>
          </div>
          <div className="mt-4 h-3 w-full rounded-full bg-slate-200">
            <div className="h-3 rounded-full bg-sky-700" style={{ width: `${overview.completionPercent}%` }} />
          </div>
        </div>
      </section>

      <section className="grid gap-6 pb-12 lg:grid-cols-[1.05fr_0.95fr]">
        <article className="panel rounded-2xl p-6">
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-xl font-semibold text-slate-900">Next Actions</h2>
            <span className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">Prioritized</span>
          </div>
          <div className="mt-4 space-y-3">
            {nextActions.map((module) => (
              <div key={module.id} className="rounded-xl border border-slate-200 bg-white p-4">
                <div className="flex items-center justify-between gap-2">
                  <p className="text-sm font-semibold text-slate-900">{module.title}</p>
                  <span className="rounded-md bg-slate-100 px-2 py-1 text-xs text-slate-700">
                    {module.status.replace('_', ' ')}
                  </span>
                </div>
                <p className="mt-2 text-sm text-slate-600">{module.objective}</p>
                <p className="mt-2 text-xs text-slate-500">
                  Point: this is the highest-impact next move to keep flow and reduce downstream blockers.
                </p>
              </div>
            ))}
          </div>
          <a
            href="/labs"
            className="mt-5 inline-flex rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-800 hover:bg-slate-50"
          >
            Manage Modules
          </a>
        </article>

        <article className="panel rounded-2xl p-6">
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-xl font-semibold text-slate-900">Recent Journal</h2>
            <a href="/journal" className="text-sm font-medium text-sky-700 hover:text-sky-800">
              View all
            </a>
          </div>
          <div className="mt-4 space-y-3">
            {journal.map((entry) => (
              <div key={entry.id} className="rounded-xl border border-slate-200 bg-white p-4">
                <div className="flex items-center justify-between gap-3">
                  <span className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">{entry.type}</span>
                  <span className="text-xs text-slate-500">{formatDate(entry.createdAt)}</span>
                </div>
                <p className="mt-2 text-sm text-slate-700">{entry.message}</p>
                <p className="mt-2 text-xs text-slate-500">
                  Point: this operational history explains why decisions were made and what changed.
                </p>
              </div>
            ))}
          </div>
        </article>
      </section>
    </div>
  );
}
