'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

const completedPagesStorageKey = 'wiki.completed.pages';
const completedModulesStorageKey = 'wiki.completed.modules';

interface WikiProgressPanelProps {
  totalPages: number;
  totalModules: number;
  pagesPerModule: number;
  basePath?: string;
}

function parseNumberList(rawValue: string | null): number[] {
  if (!rawValue) return [];
  try {
    const parsed = JSON.parse(rawValue) as unknown;
    if (!Array.isArray(parsed)) return [];
    return Array.from(
      new Set(parsed.filter((value): value is number => Number.isInteger(value) && value > 0)),
    ).sort((a, b) => a - b);
  } catch {
    return [];
  }
}

function getCompletedModules(
  completedPages: number[],
  manuallyCheckedModules: number[],
  totalModules: number,
  pagesPerModule: number,
): number {
  const completedModuleSet = new Set(
    manuallyCheckedModules.filter((moduleNumber) => moduleNumber >= 1 && moduleNumber <= totalModules),
  );
  const completedPagesSet = new Set(completedPages);

  for (let moduleNumber = 1; moduleNumber <= totalModules; moduleNumber += 1) {
    const startPage = (moduleNumber - 1) * pagesPerModule + 1;
    let moduleCompletedByPages = true;
    for (let pageNumber = startPage; pageNumber < startPage + pagesPerModule; pageNumber += 1) {
      if (!completedPagesSet.has(pageNumber)) {
        moduleCompletedByPages = false;
        break;
      }
    }
    if (moduleCompletedByPages) {
      completedModuleSet.add(moduleNumber);
    }
  }

  return completedModuleSet.size;
}

export default function WikiProgressPanel({
  totalPages,
  totalModules,
  pagesPerModule,
  basePath = '/labs',
}: WikiProgressPanelProps) {
  const router = useRouter();
  const normalizedBasePath = basePath.endsWith('/') ? basePath.slice(0, -1) : basePath;
  const [completedCount, setCompletedCount] = useState(0);
  const [completedModulesCount, setCompletedModulesCount] = useState(0);
  const [jumpPage, setJumpPage] = useState('');
  const [jumpError, setJumpError] = useState('');

  useEffect(() => {
    const syncProgress = () => {
      const completedPages = parseNumberList(localStorage.getItem(completedPagesStorageKey));
      const manuallyCheckedModules = parseNumberList(localStorage.getItem(completedModulesStorageKey));

      setCompletedCount(completedPages.length);
      setCompletedModulesCount(
        getCompletedModules(completedPages, manuallyCheckedModules, totalModules, pagesPerModule),
      );
    };

    syncProgress();

    const onStorage = (event: StorageEvent) => {
      if (
        !event.key ||
        event.key === completedPagesStorageKey ||
        event.key === completedModulesStorageKey
      ) {
        syncProgress();
      }
    };

    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, [pagesPerModule, totalModules]);

  function resetProgress() {
    for (let pageNumber = 1; pageNumber <= totalPages; pageNumber += 1) {
      localStorage.removeItem(`wiki.page.${pageNumber}.checks`);
      localStorage.removeItem(`wiki.page.${pageNumber}.notes`);
    }
    localStorage.removeItem(completedPagesStorageKey);
    localStorage.removeItem(completedModulesStorageKey);
    setCompletedCount(0);
    setCompletedModulesCount(0);
  }

  function jumpToPage(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setJumpError('');

    const target = Number(jumpPage);
    if (!Number.isInteger(target) || target < 1 || target > totalPages) {
      setJumpError(`Enter a page number between 1 and ${totalPages}.`);
      return;
    }

    router.push(`${normalizedBasePath}/${target}`);
  }

  const pagePercent = Math.round((completedCount / totalPages) * 100);
  const modulePercent = Math.round((completedModulesCount / totalModules) * 100);

  return (
    <section className="panel rounded-2xl p-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">Interactive Progress</p>
          <h2 className="mt-2 text-2xl font-semibold text-slate-900">
            {completedCount}/{totalPages} pages complete
          </h2>
          <p className="mt-1 text-sm text-slate-600">
            {completedModulesCount}/{totalModules} modules checked complete.
          </p>
        </div>
        <button
          type="button"
          onClick={resetProgress}
          className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          Reset Progress
        </button>
      </div>

      <div className="mt-4 h-3 w-full rounded-full bg-slate-200">
        <div className="h-3 rounded-full bg-sky-700 transition-all duration-500" style={{ width: `${pagePercent}%` }} />
      </div>
      <p className="mt-1 text-xs text-slate-500">{pagePercent}% page completion</p>

      <div className="mt-3 h-2.5 w-full rounded-full bg-slate-200">
        <div className="h-2.5 rounded-full bg-emerald-600 transition-all duration-500" style={{ width: `${modulePercent}%` }} />
      </div>
      <p className="mt-1 text-xs text-slate-500">{modulePercent}% module completion</p>

      <form className="mt-4 flex flex-wrap items-center gap-2" onSubmit={jumpToPage}>
        <label htmlFor="jump-page" className="text-sm font-medium text-slate-700">
          Jump to page
        </label>
        <input
          id="jump-page"
          type="number"
          min={1}
          max={totalPages}
          value={jumpPage}
          onChange={(event) => setJumpPage(event.target.value)}
          className="w-28 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm"
          placeholder="1"
        />
        <button
          type="submit"
          className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800"
        >
          Open
        </button>
        {jumpError && <p className="w-full text-xs text-rose-700">{jumpError}</p>}
      </form>
    </section>
  );
}
