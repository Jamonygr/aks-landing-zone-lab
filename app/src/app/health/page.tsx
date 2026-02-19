'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';

type HealthState = 'loading' | 'ready' | 'error';

type HealthResponse = Record<string, string>;

function statusPillClass(status: string | undefined): string {
  if (status === 'healthy') return 'bg-emerald-100 text-emerald-800';
  if (status === 'degraded') return 'bg-amber-100 text-amber-800';
  return 'bg-rose-100 text-rose-800';
}

export default function HealthPage() {
  const [state, setState] = useState<HealthState>('loading');
  const [payload, setPayload] = useState<HealthResponse>({});
  const [errorMessage, setErrorMessage] = useState<string>('');

  useEffect(() => {
    let active = true;

    async function loadHealth() {
      try {
        const response = await fetch('/api/health', {
          cache: 'no-store',
        });

        const data = (await response.json()) as HealthResponse;
        if (!active) return;

        setPayload(data);
        setState('ready');
      } catch {
        if (!active) return;
        setErrorMessage('Unable to load health status right now.');
        setState('error');
      }
    }

    loadHealth();
    return () => {
      active = false;
    };
  }, []);

  const rows = useMemo(() => Object.entries(payload), [payload]);
  const currentStatus = payload.status || 'unknown';

  return (
    <div className="mx-auto max-w-5xl px-4 py-12 sm:px-6 lg:px-8">
      <section className="mb-8">
        <p className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">AKS Lab App</p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl">Health</h1>
        <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-600">
          Application and dependency health signals from the runtime environment.
        </p>
      </section>

      <section className="panel rounded-2xl p-6">
        {state === 'loading' && <p className="text-sm text-slate-600">Loading health status...</p>}

        {state === 'error' && (
          <p className="rounded-md border border-rose-300 bg-rose-50 px-3 py-2 text-sm text-rose-700">
            {errorMessage}
          </p>
        )}

        {state === 'ready' && (
          <>
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <h2 className="text-xl font-semibold text-slate-900">Current Status</h2>
              <span className={`rounded-full px-3 py-1 text-xs font-semibold uppercase ${statusPillClass(currentStatus)}`}>
                {currentStatus}
              </span>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              {rows.map(([key, value]) => (
                <div key={key} className="rounded-xl border border-slate-200 bg-white p-4">
                  <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">{key}</p>
                  <p className="mt-1 break-all text-sm font-medium text-slate-800">{value}</p>
                </div>
              ))}
            </div>

            <div className="mt-5">
              <Link href="/api/health" className="text-sm font-medium text-sky-700 hover:text-sky-800">
                Open raw API response
              </Link>
            </div>
          </>
        )}
      </section>
    </div>
  );
}
