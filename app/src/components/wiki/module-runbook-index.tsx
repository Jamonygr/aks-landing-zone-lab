import Link from 'next/link';
import WikiModuleCompletionToggle from '@/components/wiki/wiki-module-completion-toggle';
import WikiProgressPanel from '@/components/wiki/wiki-progress-panel';
import { PAGES_PER_MODULE, TOTAL_MODULES, TOTAL_WIKI_PAGES, type WikiAccent, listWikiModules } from '@/lib/wiki';

function cardAccent(accent: WikiAccent): string {
  if (accent === 'sky') return 'border-sky-200 bg-gradient-to-br from-sky-50 to-white';
  if (accent === 'teal') return 'border-teal-200 bg-gradient-to-br from-teal-50 to-white';
  if (accent === 'amber') return 'border-amber-200 bg-gradient-to-br from-amber-50 to-white';
  if (accent === 'indigo') return 'border-indigo-200 bg-gradient-to-br from-indigo-50 to-white';
  return 'border-rose-200 bg-gradient-to-br from-rose-50 to-white';
}

function dotAccent(accent: WikiAccent): string {
  if (accent === 'sky') return 'bg-sky-600';
  if (accent === 'teal') return 'bg-teal-600';
  if (accent === 'amber') return 'bg-amber-600';
  if (accent === 'indigo') return 'bg-indigo-600';
  return 'bg-rose-600';
}

interface ModuleRunbookIndexProps {
  embedded?: boolean;
  sectionId?: string;
}

export default function ModuleRunbookIndex({ embedded = false, sectionId }: ModuleRunbookIndexProps) {
  const modules = listWikiModules();
  const pagesPerModule = PAGES_PER_MODULE;
  const wrapperClass = embedded ? '' : 'mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8';

  return (
    <div id={sectionId} className={wrapperClass}>
      <section className="synth-hero relative mb-8 rounded-3xl p-6 sm:p-8">
        <div className="pointer-events-none absolute -right-10 -top-10 h-40 w-40 rounded-full bg-sky-200/45 blur-2xl" />
        <div className="pointer-events-none absolute -bottom-12 left-1/3 h-44 w-44 rounded-full bg-teal-200/45 blur-2xl" />
        <div className="relative">
          <p className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">AKS Lab App</p>
          <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl">
            Module Runbook
          </h1>
          <p className="mono-label synth-chip mt-3 inline-flex rounded-full px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em]">
            {TOTAL_WIKI_PAGES} total pages active
          </p>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-600">
            Runbook steps are now fused under Modules. Track platform module delivery and runbook completion in one place.
          </p>
          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-white/80 p-3">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Pages</p>
              <p className="mt-1 text-2xl font-semibold text-slate-900">{TOTAL_WIKI_PAGES}</p>
              <p className="mt-1 text-xs text-slate-500">Primary runbook count</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white/80 p-3">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Lab Modules</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">{TOTAL_MODULES}</p>
              <p className="mt-1 text-xs text-slate-500">{pagesPerModule} pages per module</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white/80 p-3">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Tracks</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">5</p>
              <p className="mt-1 text-xs text-slate-500">Foundation to operations</p>
            </div>
          </div>
          <p className="mt-3 text-xs text-slate-500">
            This runbook shows <span className="font-semibold text-slate-700">{TOTAL_MODULES} modules</span> with{' '}
            <span className="font-semibold text-slate-700">{pagesPerModule} pages each</span>, totaling{' '}
            <span className="font-semibold text-slate-700">{TOTAL_WIKI_PAGES} pages</span>.
          </p>
        </div>
      </section>

      <WikiProgressPanel
        totalPages={TOTAL_WIKI_PAGES}
        totalModules={TOTAL_MODULES}
        pagesPerModule={PAGES_PER_MODULE}
        basePath="/labs"
      />

      <section className="mt-6 space-y-4">
        {modules.map((module) => (
          <article key={module.moduleNumber} className="panel rounded-2xl p-5">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Lab Module {module.moduleNumber}</h2>
                <p className="text-xs text-slate-600">{module.moduleTheme}</p>
              </div>
              <div className="flex flex-wrap items-center gap-2 text-xs">
                <WikiModuleCompletionToggle
                  moduleNumber={module.moduleNumber}
                  pageNumbers={module.pages.map((page) => page.pageNumber)}
                />
                <span className="mono-label rounded-full bg-slate-100 px-2.5 py-1 uppercase text-slate-600">
                  Pages {module.pages[0].pageNumber}-{module.pages[module.pages.length - 1].pageNumber}
                </span>
                <span className="mono-label rounded-full bg-slate-100 px-2.5 py-1 uppercase text-slate-600">
                  fused under modules
                </span>
              </div>
            </div>

            <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
              {module.pages.map((page) => (
                <Link
                  key={page.pageNumber}
                  href={page.path}
                  className={`rounded-xl border p-3 transition hover:-translate-y-0.5 hover:shadow-sm ${cardAccent(page.categoryAccent)}`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-600">
                      Page {page.pageNumber}
                    </p>
                    <span className={`h-2.5 w-2.5 rounded-full ${dotAccent(page.categoryAccent)}`} />
                  </div>
                  <p className="mt-1 text-sm font-semibold text-slate-900">{page.categoryShortLabel}</p>
                  <p className="mt-1 text-xs text-slate-600">{page.focusArea}</p>
                  <p className="mt-2 line-clamp-4 text-xs text-slate-700">{page.summary}</p>
                  <div className="mt-2 flex flex-wrap gap-2 text-[11px] text-slate-600">
                    <span className="rounded-full border border-slate-300 bg-white/70 px-2 py-0.5">
                      {page.difficulty}
                    </span>
                    <span className="rounded-full border border-slate-300 bg-white/70 px-2 py-0.5">
                      {page.estimatedMinutes} min
                    </span>
                  </div>
                </Link>
              ))}
            </div>
          </article>
        ))}
      </section>
    </div>
  );
}
