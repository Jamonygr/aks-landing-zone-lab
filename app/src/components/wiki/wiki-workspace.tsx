'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import type { WikiPage, WikiAccent } from '@/lib/wiki';

const completedPagesStorageKey = 'wiki.completed.pages';

interface ModuleTab {
  label: string;
  pageNumber: number;
  path: string;
  accent: WikiAccent;
}

interface WikiWorkspaceProps {
  page: WikiPage;
  totalPages: number;
  moduleTabs: ModuleTab[];
  basePath?: string;
  indexPath?: string;
  indexLabel?: string;
}

function describePrerequisitePurpose(item: string): string {
  const text = item.toLowerCase();
  if (text.includes('credentials')) {
    return 'Prevents auth failures and ensures commands execute with fresh cluster access.';
  }
  if (text.includes('active context') || text.includes('context')) {
    return 'Avoids running commands against the wrong cluster or subscription.';
  }
  if (text.includes('access')) {
    return 'Confirms required namespaces are reachable before validation starts.';
  }
  if (text.includes('notes')) {
    return 'Creates an audit trail so decisions and outcomes are traceable.';
  }
  if (text.includes('dns') || text.includes('ingress')) {
    return 'Makes network tests repeatable by removing endpoint ambiguity.';
  }
  if (text.includes('identity') || text.includes('key vault')) {
    return 'Validates secure secret access paths before workload checks.';
  }
  if (text.includes('rollback plan')) {
    return 'Limits blast radius when a drill introduces instability.';
  }
  return 'Reduces setup risk so execution results are trustworthy.';
}

function describeSignalPurpose(item: string): string {
  const text = item.toLowerCase();
  if (text.includes('readiness') || text.includes('scheduling')) {
    return 'Surfaces cluster pressure early before workloads fail placement.';
  }
  if (text.includes('dns') || text.includes('nxdomain')) {
    return 'Detects name-resolution drift that breaks service connectivity.';
  }
  if (text.includes('status code')) {
    return 'Shows customer-facing impact quickly during rollouts.';
  }
  if (text.includes('rbac') || text.includes('allow') || text.includes('deny')) {
    return 'Reveals privilege drift and access-control regressions.';
  }
  if (text.includes('secret') || text.includes('token federation')) {
    return 'Catches identity or secret-delivery misconfigurations early.';
  }
  if (text.includes('admission')) {
    return 'Confirms policy engines enforce the intended boundaries.';
  }
  if (text.includes('rollout') || text.includes('unavailable replica')) {
    return 'Prevents hidden release degradation from reaching production.';
  }
  if (text.includes('restart')) {
    return 'Highlights unstable containers and crash-loop behavior.';
  }
  if (text.includes('latency') || text.includes('saturation')) {
    return 'Measures user-experience and capacity impact under load.';
  }
  if (text.includes('time-to-detection') || text.includes('time-to-recovery')) {
    return 'Tracks incident response effectiveness and recovery speed.';
  }
  if (text.includes('residual warnings') || text.includes('events')) {
    return 'Ensures the system is clean after mitigation, not just temporarily recovered.';
  }
  return 'Provides early warning signals so issues are addressed before escalation.';
}

function describeVerificationPurpose(item: string): string {
  const text = item.toLowerCase();
  if (text.includes('baseline') || text.includes('timestamp')) {
    return 'Provides evidence for comparison during later changes and incidents.';
  }
  if (text.includes('health checks') || text.includes('inventory')) {
    return 'Confirms your operating picture is complete before release decisions.';
  }
  if (text.includes('service discovery') || text.includes('ingress') || text.includes('routing')) {
    return 'Proves critical request paths function end-to-end.';
  }
  if (text.includes('identity') || text.includes('bindings') || text.includes('policy')) {
    return 'Validates least-privilege controls are truly enforced.';
  }
  if (text.includes('runtime pod security')) {
    return 'Ensures workload runtime posture aligns with security standards.';
  }
  if (text.includes('rollout') || text.includes('telemetry') || text.includes('scale')) {
    return 'Verifies reliability and performance through operational stress.';
  }
  if (text.includes('drill') || text.includes('post-incident') || text.includes('lessons learned')) {
    return 'Converts incident exercises into repeatable operational improvement.';
  }
  return 'Turns assumptions into verified outcomes before moving forward.';
}

function describeFailurePurpose(item: string): string {
  const text = item.toLowerCase();
  if (text.includes('502') || text.includes('504')) {
    return 'Connects edge errors to backend readiness gaps so recovery is faster.';
  }
  if (text.includes('dns')) {
    return 'Speeds triage by focusing on name-resolution and policy dependencies.';
  }
  if (text.includes('forbidden') || text.includes('access denied')) {
    return 'Separates authz drift from application bugs during incident response.';
  }
  if (text.includes('crashloop') || text.includes('restart')) {
    return 'Helps isolate unstable runtime config before it causes wider outages.';
  }
  return 'Shortens mean time to recovery by mapping symptoms to likely remediation paths.';
}

function checksStorageKey(pageNumber: number): string {
  return `wiki.page.${pageNumber}.checks`;
}

function notesStorageKey(pageNumber: number): string {
  return `wiki.page.${pageNumber}.notes`;
}

function parseNumberList(rawValue: string | null): number[] {
  if (!rawValue) return [];
  try {
    const parsed = JSON.parse(rawValue) as unknown;
    if (!Array.isArray(parsed)) return [];
    return parsed
      .filter((value): value is number => Number.isInteger(value) && value > 0)
      .sort((a, b) => a - b);
  } catch {
    return [];
  }
}

function parseChecks(rawValue: string | null): Record<string, boolean> {
  if (!rawValue) return {};
  try {
    const parsed = JSON.parse(rawValue) as unknown;
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return {};
    const record: Record<string, boolean> = {};
    for (const [key, value] of Object.entries(parsed)) {
      record[key] = value === true;
    }
    return record;
  } catch {
    return {};
  }
}

function accentClasses(accent: WikiAccent): { badge: string; panel: string; dot: string } {
  if (accent === 'sky') {
    return {
      badge: 'bg-sky-100 text-sky-800 border-sky-200',
      panel: 'from-sky-500/15 via-sky-400/10 to-cyan-300/10',
      dot: 'bg-sky-600',
    };
  }
  if (accent === 'teal') {
    return {
      badge: 'bg-teal-100 text-teal-800 border-teal-200',
      panel: 'from-teal-500/15 via-emerald-400/10 to-cyan-300/10',
      dot: 'bg-teal-600',
    };
  }
  if (accent === 'amber') {
    return {
      badge: 'bg-amber-100 text-amber-800 border-amber-200',
      panel: 'from-amber-500/15 via-orange-400/10 to-yellow-300/10',
      dot: 'bg-amber-600',
    };
  }
  if (accent === 'indigo') {
    return {
      badge: 'bg-indigo-100 text-indigo-800 border-indigo-200',
      panel: 'from-indigo-500/15 via-violet-400/10 to-sky-300/10',
      dot: 'bg-indigo-600',
    };
  }
  return {
    badge: 'bg-rose-100 text-rose-800 border-rose-200',
    panel: 'from-rose-500/15 via-pink-400/10 to-orange-300/10',
    dot: 'bg-rose-600',
  };
}

function accentRgb(accent: WikiAccent): string {
  if (accent === 'sky') return '3, 105, 161';
  if (accent === 'teal') return '15, 118, 110';
  if (accent === 'amber') return '180, 83, 9';
  if (accent === 'indigo') return '79, 70, 229';
  return '225, 29, 72';
}

function WikiIllustration({
  accent,
  pageNumber,
  moduleNumber,
  seed,
}: {
  accent: WikiAccent;
  pageNumber: number;
  moduleNumber: number;
  seed: number;
}) {
  const rgb = accentRgb(accent);
  const bars = Array.from({ length: 10 }, (_, index) => {
    const value = ((seed + index * 7) % 70) + 20;
    return {
      id: index,
      x: index * 26 + 20,
      y: 90 - value,
      h: value,
    };
  });

  return (
    <svg viewBox="0 0 320 170" className="h-full w-full">
      <defs>
        <linearGradient id="wiki-card-gradient" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={`rgba(${rgb},0.35)`} />
          <stop offset="100%" stopColor="rgba(15,23,42,0.06)" />
        </linearGradient>
      </defs>
      <rect x="0" y="0" width="320" height="170" rx="16" fill="url(#wiki-card-gradient)" />
      <rect x="16" y="14" width="112" height="28" rx="8" fill={`rgba(${rgb},0.22)`} />
      <text x="24" y="33" fill="#0f172a" fontSize="11" fontWeight="700">
        Module {moduleNumber}
      </text>
      <text x="138" y="33" fill="#0f172a" fontSize="11" fontWeight="700">
        Page {pageNumber}
      </text>
      {bars.map((bar) => (
        <rect
          key={bar.id}
          x={bar.x}
          y={bar.y}
          width="16"
          height={bar.h}
          rx="4"
          fill={`rgba(${rgb},0.65)`}
          opacity={0.55 + (bar.id % 3) * 0.15}
        />
      ))}
      <circle cx="280" cy="42" r="18" fill={`rgba(${rgb},0.45)`} />
      <circle cx="255" cy="56" r="9" fill={`rgba(${rgb},0.7)`} />
      <text x="22" y="153" fill="#334155" fontSize="10" fontWeight="600">
        AKS Lab Visual Aid
      </text>
    </svg>
  );
}

export default function WikiWorkspace({
  page,
  totalPages,
  moduleTabs,
  basePath = '/labs',
  indexPath = '/labs#module-runbook',
  indexLabel = 'Back to Modules',
}: WikiWorkspaceProps) {
  const [hydrated, setHydrated] = useState(false);
  const [checks, setChecks] = useState<Record<string, boolean>>({});
  const [notes, setNotes] = useState('');
  const [completedPages, setCompletedPages] = useState<number[]>([]);
  const [copiedStepId, setCopiedStepId] = useState<string | null>(null);
  const accent = accentClasses(page.categoryAccent);

  useEffect(() => {
    const defaultChecks = Object.fromEntries(page.steps.map((step) => [step.id, false]));
    const storedChecks = parseChecks(localStorage.getItem(checksStorageKey(page.pageNumber)));
    const storedNotes = localStorage.getItem(notesStorageKey(page.pageNumber)) || '';
    const storedCompletedPages = parseNumberList(localStorage.getItem(completedPagesStorageKey));

    setChecks({ ...defaultChecks, ...storedChecks });
    setNotes(storedNotes);
    setCompletedPages(storedCompletedPages);
    setHydrated(true);
  }, [page.pageNumber, page.steps]);

  useEffect(() => {
    if (!hydrated) return;
    localStorage.setItem(checksStorageKey(page.pageNumber), JSON.stringify(checks));
  }, [checks, hydrated, page.pageNumber]);

  useEffect(() => {
    if (!hydrated) return;
    localStorage.setItem(notesStorageKey(page.pageNumber), notes);
  }, [hydrated, notes, page.pageNumber]);

  const completedStepCount = useMemo(
    () => page.steps.filter((step) => checks[step.id]).length,
    [checks, page.steps],
  );
  const pageCompleted = page.steps.length > 0 && completedStepCount === page.steps.length;

  useEffect(() => {
    if (!hydrated) return;

    setCompletedPages((current) => {
      const nextSet = new Set(current);
      if (pageCompleted) nextSet.add(page.pageNumber);
      else nextSet.delete(page.pageNumber);

      const next = Array.from(nextSet).sort((a, b) => a - b);
      localStorage.setItem(completedPagesStorageKey, JSON.stringify(next));
      return next;
    });
  }, [hydrated, page.pageNumber, pageCompleted]);

  const completedCount = completedPages.length;
  const progressPercent = Math.round((completedCount / totalPages) * 100);
  const normalizedBasePath = basePath.endsWith('/') ? basePath.slice(0, -1) : basePath;
  const previousPath = page.pageNumber > 1 ? `${normalizedBasePath}/${page.pageNumber - 1}` : null;
  const nextPath = page.pageNumber < totalPages ? `${normalizedBasePath}/${page.pageNumber + 1}` : null;

  async function copyCommand(stepId: string, command: string): Promise<void> {
    try {
      await navigator.clipboard.writeText(command);
      setCopiedStepId(stepId);
      window.setTimeout(() => setCopiedStepId(null), 1200);
    } catch {
      setCopiedStepId(null);
    }
  }

  return (
    <div className="space-y-6">
      <section className={`panel overflow-hidden rounded-3xl border-slate-200 bg-gradient-to-br ${accent.panel}`}>
        <div className="grid gap-0 lg:grid-cols-[1.55fr_1fr]">
          <div className="p-6 sm:p-7">
            <div className="flex flex-wrap items-center gap-2">
              <span className={`rounded-full border px-2.5 py-1 text-xs font-semibold uppercase ${accent.badge}`}>
                {page.categoryFullLabel}
              </span>
              <span className="rounded-full border border-slate-300 bg-white/75 px-2.5 py-1 text-xs font-semibold uppercase text-slate-700">
                {page.difficulty}
              </span>
              <span className="rounded-full border border-slate-300 bg-white/75 px-2.5 py-1 text-xs font-semibold uppercase text-slate-700">
                {page.estimatedMinutes} min
              </span>
            </div>

            <p className="mono-label mt-4 text-xs uppercase tracking-[0.14em] text-slate-600">
              Module {page.moduleNumber} • Page {page.pageNumber}/{totalPages}
            </p>
            <h1 className="mt-2 max-w-3xl text-2xl font-semibold text-slate-900 sm:text-3xl">{page.title}</h1>
            <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-700">{page.summary}</p>
            <p className="mt-3 max-w-3xl rounded-xl border border-slate-200/80 bg-white/70 px-4 py-3 text-sm text-slate-700">
              <span className="font-semibold text-slate-900">Scenario:</span> {page.scenario}
            </p>
            <p className="mt-3 max-w-3xl text-sm text-slate-700">
              <span className="font-semibold text-slate-900">Objective:</span> {page.objective}
            </p>

            <div className="mt-5 grid gap-2 sm:grid-cols-2">
              <div className="rounded-xl border border-slate-200 bg-white/70 p-3">
                <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Module Theme</p>
                <p className="mt-1 text-sm font-semibold text-slate-800">{page.moduleTheme}</p>
              </div>
              <div className="rounded-xl border border-slate-200 bg-white/70 p-3">
                <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Focus Area</p>
                <p className="mt-1 text-sm font-semibold text-slate-800">{page.focusArea}</p>
              </div>
            </div>
          </div>

          <div className="border-t border-slate-200/70 bg-white/60 p-5 lg:border-l lg:border-t-0">
            <div className="rounded-2xl border border-slate-200 bg-white p-3 shadow-sm">
              <div className="h-44">
                <WikiIllustration
                  accent={page.categoryAccent}
                  pageNumber={page.pageNumber}
                  moduleNumber={page.moduleNumber}
                  seed={page.artSeed}
                />
              </div>
            </div>
            <div className="mt-4 rounded-2xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-xs uppercase tracking-[0.12em] text-slate-500">Global Progress</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">
                {completedCount}/{totalPages}
              </p>
              <p className="text-xs text-slate-500">{progressPercent}% complete</p>
              <div className="mt-2 h-2.5 w-full rounded-full bg-slate-200">
                <div className="h-2.5 rounded-full bg-slate-900 transition-all" style={{ width: `${progressPercent}%` }} />
              </div>
              <p className="mt-2 text-xs text-slate-500">
                This page: {completedStepCount}/{page.steps.length} steps completed.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="panel rounded-2xl p-4 sm:p-5">
        <p className="mono-label text-[11px] uppercase tracking-[0.14em] text-slate-500">Module Tabs</p>
        <div className="mt-3 overflow-x-auto">
          <div className="flex min-w-max gap-2">
            {moduleTabs.map((tab) => {
              const active = tab.pageNumber === page.pageNumber;
              const tabAccent = accentClasses(tab.accent);
              return (
                <Link
                  key={tab.pageNumber}
                  href={tab.path}
                  className={`rounded-lg border px-3 py-2 text-sm font-semibold transition ${
                    active
                      ? `${tabAccent.badge} border`
                      : 'border-slate-300 bg-white text-slate-700 hover:border-slate-400 hover:bg-slate-50'
                  }`}
                >
                  {tab.label}
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      <section className="grid gap-6 lg:grid-cols-[1.6fr_0.95fr]">
        <article className="panel rounded-2xl p-5">
          <h2 className="text-lg font-semibold text-slate-900">Execution Steps</h2>
          <p className="mt-1 text-sm text-slate-600">
            Run each step, capture output, and mark completion before proceeding.
          </p>
          <div className="mt-4 space-y-3">
            {page.steps.map((step, index) => {
              const checked = checks[step.id] === true;
              return (
                <div key={step.id} className="rounded-xl border border-slate-200 bg-white p-4">
                  <div className="flex items-start gap-3">
                    <label className="mt-0.5 inline-flex cursor-pointer items-center">
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={(event) =>
                          setChecks((current) => ({
                            ...current,
                            [step.id]: event.target.checked,
                          }))
                        }
                        className="h-4 w-4 rounded border-slate-300 text-sky-700 focus:ring-sky-600"
                      />
                    </label>
                    <div className="w-full">
                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <span className={`h-2.5 w-2.5 rounded-full ${accent.dot}`} />
                          <p className="text-sm font-semibold text-slate-900">
                            {index + 1}. {step.title}
                          </p>
                        </div>
                        <span
                          className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                            checked ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-700'
                          }`}
                        >
                          {checked ? 'Done' : 'Pending'}
                        </span>
                      </div>
                      <p className="mt-2 text-sm text-slate-600">{step.description}</p>
                      {step.command && (
                        <div className="mt-3 rounded-xl border border-slate-200 bg-slate-950 p-3">
                          <div className="mb-2 flex items-center justify-between gap-2">
                            <span className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-300">
                              Command
                            </span>
                            <button
                              type="button"
                              onClick={() => copyCommand(step.id, step.command as string)}
                              className="rounded-md bg-slate-800 px-2.5 py-1 text-xs font-medium text-slate-100 hover:bg-slate-700"
                            >
                              {copiedStepId === step.id ? 'Copied' : 'Copy'}
                            </button>
                          </div>
                          <pre className="overflow-x-auto text-xs text-slate-100">
                            <code>{step.command}</code>
                          </pre>
                        </div>
                      )}
                      <div className="mt-3 grid gap-2 sm:grid-cols-2">
                        <p className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-700">
                          <span className="font-semibold text-slate-900">Expected:</span> {step.expected}
                        </p>
                        <p className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-700">
                          <span className="font-semibold text-slate-900">Why it matters:</span> {step.whyItMatters}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </article>

        <aside className="space-y-4">
          <section className="panel rounded-2xl p-5">
            <h2 className="text-base font-semibold text-slate-900">Prerequisites</h2>
            <p className="mt-1 text-xs text-slate-500">Each point includes why it matters before you begin execution.</p>
            <ul className="mt-3 space-y-2 text-sm text-slate-700">
              {page.prerequisites.map((item) => (
                <li key={item} className="rounded-lg border border-slate-200 bg-white px-3 py-2">
                  <p>{item}</p>
                  <p className="mt-1 text-xs text-slate-500">
                    <span className="font-semibold text-slate-700">Why:</span> {describePrerequisitePurpose(item)}
                  </p>
                </li>
              ))}
            </ul>
          </section>

          <section className="panel rounded-2xl p-5">
            <h2 className="text-base font-semibold text-slate-900">Signals To Watch</h2>
            <p className="mt-1 text-xs text-slate-500">Watch these to understand why conditions are changing in real time.</p>
            <ul className="mt-3 space-y-2 text-sm text-slate-700">
              {page.signalsToWatch.map((item) => (
                <li key={item} className="rounded-lg border border-slate-200 bg-white px-3 py-2">
                  <p>{item}</p>
                  <p className="mt-1 text-xs text-slate-500">
                    <span className="font-semibold text-slate-700">Why:</span> {describeSignalPurpose(item)}
                  </p>
                </li>
              ))}
            </ul>
          </section>
        </aside>
      </section>

      <section className="grid gap-6 lg:grid-cols-2">
        <article className="panel rounded-2xl p-5">
          <h2 className="text-lg font-semibold text-slate-900">Verification Checklist</h2>
          <p className="mt-1 text-xs text-slate-500">Each verification explains the point of the check, not only the expected state.</p>
          <div className="mt-3 space-y-2">
            {page.verifications.map((item) => (
              <div key={item} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700">
                <p>{item}</p>
                <p className="mt-1 text-xs text-slate-500">
                  <span className="font-semibold text-slate-700">Why:</span> {describeVerificationPurpose(item)}
                </p>
              </div>
            ))}
          </div>
        </article>

        <article className="panel rounded-2xl p-5">
          <h2 className="text-lg font-semibold text-slate-900">Common Failure Patterns</h2>
          <p className="mt-1 text-xs text-slate-500">Use these patterns to understand why failures happen and what action to take.</p>
          <div className="mt-3 space-y-3">
            {page.commonFailures.map((failure) => (
              <div key={failure.symptom} className="rounded-lg border border-slate-200 bg-white p-3 text-sm">
                <p className="font-semibold text-slate-900">{failure.symptom}</p>
                <p className="mt-1 text-slate-700">
                  <span className="font-medium text-slate-800">Likely cause:</span> {failure.likelyCause}
                </p>
                <p className="mt-1 text-slate-700">
                  <span className="font-medium text-slate-800">Recovery:</span> {failure.recovery}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  <span className="font-semibold text-slate-700">Why this pattern matters:</span>{' '}
                  {describeFailurePurpose(failure.symptom)}
                </p>
              </div>
            ))}
          </div>
        </article>
      </section>

      <section className="panel rounded-2xl p-5">
        <label className="text-sm font-semibold text-slate-800" htmlFor="module-notes">
          Operator Notes
        </label>
        <p className="mt-1 text-xs text-slate-500">{page.notesPrompt}</p>
        <textarea
          id="module-notes"
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
          rows={7}
          placeholder="Capture findings, blockers, command outputs, and decisions."
          className="mt-3 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700"
        />
        <p className="mt-2 text-xs text-slate-500">
          {hydrated ? 'Stored in this browser.' : ''} Completion: {completedStepCount}/{page.steps.length} steps.
        </p>
      </section>

      <section className="flex flex-wrap items-center justify-between gap-3">
        {previousPath ? (
          <Link
            href={previousPath}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            Previous Page
          </Link>
        ) : (
          <span />
        )}

        <Link
          href={indexPath}
          className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          {indexLabel}
        </Link>

        {nextPath ? (
          <Link
            href={nextPath}
            className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800"
          >
            Next Page
          </Link>
        ) : (
          <span />
        )}
      </section>
    </div>
  );
}
