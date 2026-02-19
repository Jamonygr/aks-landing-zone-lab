import JournalFeed from '@/components/lab/journal-feed';
import { getLabJournal } from '@/lib/lab';

export const dynamic = 'force-dynamic';

export default async function JournalPage() {
  const entries = await getLabJournal(30);
  const entriesVm = entries.map((entry) => ({
    ...entry,
    createdAt: entry.createdAt.toISOString(),
  }));

  return (
    <div className="mx-auto max-w-5xl px-4 py-12 sm:px-6 lg:px-8">
      <section className="mb-8">
        <p className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">AKS Lab App</p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl">
          Operations Journal
        </h1>
        <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-600">
          Keep a single running log of deployments, validation checks, and blockers while you execute the lab.
        </p>
      </section>

      <JournalFeed initialEntries={entriesVm} />
    </div>
  );
}
