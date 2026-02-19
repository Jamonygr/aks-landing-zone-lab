'use client';

import { useMemo, useState } from 'react';

type ModuleStatus = 'planned' | 'in_progress' | 'blocked' | 'completed';
type CheckpointStatus = 'todo' | 'done';

interface LabCheckpointVm {
  id: number;
  moduleId: number;
  title: string;
  status: CheckpointStatus;
  evidence: string;
  updatedAt: string;
}

interface LabModuleVm {
  id: number;
  code: string;
  title: string;
  objective: string;
  owner: string;
  status: ModuleStatus;
  sortOrder: number;
  updatedAt: string;
  checkpoints: LabCheckpointVm[];
}

interface LabOverviewVm {
  totalModules: number;
  completedModules: number;
  blockedModules: number;
  totalCheckpoints: number;
  completedCheckpoints: number;
  completionPercent: number;
}

interface BoardProps {
  initialModules: LabModuleVm[];
  initialOverview: LabOverviewVm;
}

const moduleStatusOptions: Array<{ value: ModuleStatus; label: string }> = [
  { value: 'planned', label: 'Planned' },
  { value: 'in_progress', label: 'In Progress' },
  { value: 'blocked', label: 'Blocked' },
  { value: 'completed', label: 'Completed' },
];

const moduleStatusStyles: Record<ModuleStatus, string> = {
  planned: 'bg-slate-100 text-slate-700',
  in_progress: 'bg-sky-100 text-sky-800',
  blocked: 'bg-rose-100 text-rose-700',
  completed: 'bg-emerald-100 text-emerald-700',
};

function formatDate(value: string): string {
  return new Date(value).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default function LabBoard({ initialModules, initialOverview }: BoardProps) {
  const [modules, setModules] = useState(initialModules);
  const [overview, setOverview] = useState(initialOverview);
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const blockedModules = useMemo(
    () => modules.filter((module) => module.status === 'blocked'),
    [modules],
  );

  async function updateModuleStatus(moduleId: number, status: ModuleStatus) {
    setError(null);
    setBusyKey(`module-${moduleId}`);
    try {
      const response = await fetch(`/api/lab/modules/${moduleId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });

      const payload = (await response.json()) as {
        error?: string;
        module?: { status: ModuleStatus; updatedAt: string };
        overview?: LabOverviewVm;
      };

      if (!response.ok || !payload.module || !payload.overview) {
        throw new Error(payload.error || 'Unable to update module status.');
      }

      const updatedModule = payload.module;
      setModules((current) =>
        current.map((module) =>
          module.id === moduleId
            ? { ...module, status: updatedModule.status, updatedAt: updatedModule.updatedAt }
            : module,
        ),
      );
      setOverview(payload.overview);
    } catch (requestError) {
      const message = requestError instanceof Error ? requestError.message : 'Unexpected request error.';
      setError(message);
    } finally {
      setBusyKey(null);
    }
  }

  async function toggleCheckpoint(checkpointId: number, currentStatus: CheckpointStatus) {
    const nextStatus: CheckpointStatus = currentStatus === 'done' ? 'todo' : 'done';
    setError(null);
    setBusyKey(`checkpoint-${checkpointId}`);

    try {
      const response = await fetch(`/api/lab/checkpoints/${checkpointId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: nextStatus }),
      });

      const payload = (await response.json()) as {
        error?: string;
        checkpoint?: { id: number; status: CheckpointStatus; updatedAt: string };
        overview?: LabOverviewVm;
      };

      if (!response.ok || !payload.checkpoint || !payload.overview) {
        throw new Error(payload.error || 'Unable to update checkpoint.');
      }

      const updatedCheckpoint = payload.checkpoint;
      setModules((current) =>
        current.map((module) => ({
          ...module,
          checkpoints: module.checkpoints.map((checkpoint) =>
            checkpoint.id === checkpointId
              ? {
                  ...checkpoint,
                  status: updatedCheckpoint.status,
                  updatedAt: updatedCheckpoint.updatedAt,
                }
              : checkpoint,
          ),
        })),
      );
      setOverview(payload.overview);
    } catch (requestError) {
      const message = requestError instanceof Error ? requestError.message : 'Unexpected request error.';
      setError(message);
    } finally {
      setBusyKey(null);
    }
  }

  return (
    <div className="space-y-6">
      <section className="panel rounded-2xl p-6">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">Lab Completion</p>
            <h2 className="mt-2 text-2xl font-semibold text-slate-900">
              {overview.completedCheckpoints}/{overview.totalCheckpoints} checkpoints complete
            </h2>
            <p className="mt-1 text-sm text-slate-600">
              {overview.completedModules}/{overview.totalModules} modules completed, {overview.blockedModules} blocked.
            </p>
          </div>
          <span className="rounded-xl bg-slate-900 px-3 py-2 text-sm font-semibold text-white">
            {overview.completionPercent}% overall
          </span>
        </div>
        <div className="mt-4 h-3 w-full rounded-full bg-slate-200">
          <div
            className="h-3 rounded-full bg-sky-700 transition-all duration-500"
            style={{ width: `${overview.completionPercent}%` }}
          />
        </div>
      </section>

      {error && (
        <section className="rounded-xl border border-rose-300 bg-rose-50 px-4 py-3 text-sm text-rose-700">
          {error}
        </section>
      )}

      {blockedModules.length > 0 && (
        <section className="rounded-xl border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          Blocked now: {blockedModules.map((module) => module.code).join(', ')}
        </section>
      )}

      <section className="space-y-4">
        {modules.map((module) => (
          <article key={module.id} className="panel rounded-2xl p-6">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <p className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">{module.code}</p>
                <h3 className="mt-1 text-xl font-semibold text-slate-900">{module.title}</h3>
                <p className="mt-2 max-w-3xl text-sm text-slate-600">{module.objective}</p>
                <p className="mt-2 text-xs text-slate-500">
                  Owner: {module.owner} • Last update: {formatDate(module.updatedAt)}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <span className={`rounded-md px-2 py-1 text-xs font-medium ${moduleStatusStyles[module.status]}`}>
                  {module.status.replace('_', ' ')}
                </span>
                <label className="sr-only" htmlFor={`module-status-${module.id}`}>
                  Update status for {module.title}
                </label>
                <select
                  id={`module-status-${module.id}`}
                  value={module.status}
                  onChange={(event) => updateModuleStatus(module.id, event.target.value as ModuleStatus)}
                  disabled={busyKey === `module-${module.id}`}
                  className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700"
                >
                  {moduleStatusOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="mt-5 grid gap-2">
              {module.checkpoints.map((checkpoint) => {
                const done = checkpoint.status === 'done';
                return (
                  <button
                    key={checkpoint.id}
                    type="button"
                    onClick={() => toggleCheckpoint(checkpoint.id, checkpoint.status)}
                    disabled={busyKey === `checkpoint-${checkpoint.id}`}
                    className={`w-full rounded-lg border px-4 py-3 text-left transition ${
                      done
                        ? 'border-emerald-200 bg-emerald-50 hover:bg-emerald-100'
                        : 'border-slate-200 bg-white hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex flex-wrap items-center justify-between gap-3">
                      <span className="text-sm font-medium text-slate-800">
                        {done ? 'Done' : 'Todo'}: {checkpoint.title}
                      </span>
                      <span className="text-xs text-slate-500">{formatDate(checkpoint.updatedAt)}</span>
                    </div>
                    <p className="mt-1 text-xs text-slate-600">{checkpoint.evidence}</p>
                  </button>
                );
              })}
            </div>
          </article>
        ))}
      </section>
    </div>
  );
}
