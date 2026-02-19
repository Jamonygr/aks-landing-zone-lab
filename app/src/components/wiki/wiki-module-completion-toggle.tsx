'use client';

import { useEffect, useMemo, useState } from 'react';

const completedPagesStorageKey = 'wiki.completed.pages';
const completedModulesStorageKey = 'wiki.completed.modules';

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

interface WikiModuleCompletionToggleProps {
  moduleNumber: number;
  pageNumbers: number[];
}

export default function WikiModuleCompletionToggle({
  moduleNumber,
  pageNumbers,
}: WikiModuleCompletionToggleProps) {
  const [hydrated, setHydrated] = useState(false);
  const [manuallyCheckedModules, setManuallyCheckedModules] = useState<number[]>([]);
  const [completedPages, setCompletedPages] = useState<number[]>([]);

  useEffect(() => {
    const syncFromStorage = () => {
      setManuallyCheckedModules(parseNumberList(localStorage.getItem(completedModulesStorageKey)));
      setCompletedPages(parseNumberList(localStorage.getItem(completedPagesStorageKey)));
    };

    syncFromStorage();
    setHydrated(true);

    const onStorage = (event: StorageEvent) => {
      if (
        !event.key ||
        event.key === completedModulesStorageKey ||
        event.key === completedPagesStorageKey
      ) {
        syncFromStorage();
      }
    };

    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  const autoCompleted = useMemo(() => {
    if (pageNumbers.length === 0) return false;
    const completedSet = new Set(completedPages);
    return pageNumbers.every((pageNumber) => completedSet.has(pageNumber));
  }, [completedPages, pageNumbers]);

  const manuallyChecked = manuallyCheckedModules.includes(moduleNumber);
  const checked = autoCompleted || manuallyChecked;

  function toggleManualCheck() {
    setManuallyCheckedModules((current) => {
      const nextSet = new Set(current);
      if (nextSet.has(moduleNumber)) nextSet.delete(moduleNumber);
      else nextSet.add(moduleNumber);

      const next = Array.from(nextSet).sort((a, b) => a - b);
      localStorage.setItem(completedModulesStorageKey, JSON.stringify(next));
      return next;
    });
  }

  const label = checked ? (autoCompleted ? 'Completed' : 'Checked') : 'Mark Done';

  return (
    <button
      type="button"
      onClick={toggleManualCheck}
      disabled={!hydrated}
      className={`mono-label inline-flex items-center gap-2 rounded-full border px-2.5 py-1 uppercase transition ${
        checked
          ? 'border-emerald-300 bg-emerald-100 text-emerald-800'
          : 'border-slate-300 bg-slate-100 text-slate-600 hover:border-slate-400'
      } ${!hydrated ? 'opacity-60' : ''}`}
      aria-pressed={manuallyChecked}
      aria-label={`Toggle completion check for module ${moduleNumber}`}
      title={autoCompleted ? 'All pages in this module are complete.' : 'Manually check module completion.'}
    >
      <span className={`h-2.5 w-2.5 rounded-full ${checked ? 'bg-emerald-600' : 'bg-slate-400'}`} />
      {label}
    </button>
  );
}
