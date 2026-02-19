import LabBoard from '@/components/lab/lab-board';
import ModuleRunbookIndex from '@/components/wiki/module-runbook-index';
import { getLabModules, getLabOverview } from '@/lib/lab';

export const dynamic = 'force-dynamic';

export default async function LabsPage() {
  const [modules, overview] = await Promise.all([getLabModules(), getLabOverview()]);

  const modulesVm = modules.map((module) => ({
    ...module,
    updatedAt: module.updatedAt.toISOString(),
    checkpoints: module.checkpoints.map((checkpoint) => ({
      ...checkpoint,
      updatedAt: checkpoint.updatedAt.toISOString(),
    })),
  }));

  return (
    <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:px-8">
      <section className="mb-8">
        <p className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">AKS Lab App</p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl">
          Module Tracker
        </h1>
        <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-600">
          Update module status, complete checkpoints, and track whether your AKS landing zone lab is moving
          forward or blocked.
        </p>
      </section>

      <LabBoard initialModules={modulesVm} initialOverview={overview} />

      <section className="mt-12">
        <ModuleRunbookIndex embedded sectionId="module-runbook" />
      </section>
    </div>
  );
}
