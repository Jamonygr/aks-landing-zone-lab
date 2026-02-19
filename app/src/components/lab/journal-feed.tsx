'use client';

import { FormEvent, useState } from 'react';

type JournalType = 'deploy' | 'validate' | 'incident' | 'note';

interface JournalEntryVm {
  id: number;
  type: JournalType;
  message: string;
  createdAt: string;
}

interface JournalFeedProps {
  initialEntries: JournalEntryVm[];
}

const typeStyles: Record<JournalType, string> = {
  deploy: 'bg-sky-100 text-sky-800',
  validate: 'bg-emerald-100 text-emerald-800',
  incident: 'bg-rose-100 text-rose-800',
  note: 'bg-slate-200 text-slate-800',
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

export default function JournalFeed({ initialEntries }: JournalFeedProps) {
  const [entries, setEntries] = useState(initialEntries);
  const [entryType, setEntryType] = useState<JournalType>('note');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

    if (!message.trim()) {
      setError('Please enter a message.');
      return;
    }

    setSaving(true);
    try {
      const response = await fetch('/api/lab/journal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: entryType, message: message.trim() }),
      });

      const payload = (await response.json()) as {
        error?: string;
        entry?: JournalEntryVm;
      };

      if (!response.ok || !payload.entry) {
        throw new Error(payload.error || 'Unable to save entry.');
      }

      const newEntry = payload.entry;
      setEntries((current) => [newEntry, ...current].slice(0, 50));
      setMessage('');
      setEntryType('note');
    } catch (submitError) {
      const resolvedMessage = submitError instanceof Error ? submitError.message : 'Unexpected request error.';
      setError(resolvedMessage);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <section className="panel rounded-2xl p-6">
        <h2 className="text-xl font-semibold text-slate-900">Add Lab Journal Entry</h2>
        <p className="mt-1 text-sm text-slate-600">
          Record deployments, validations, incidents, and notes while you run the lab.
        </p>
        <form className="mt-4 grid gap-3" onSubmit={onSubmit}>
          <label className="grid gap-1 text-sm text-slate-700" htmlFor="entry-type">
            Entry Type
            <select
              id="entry-type"
              value={entryType}
              onChange={(event) => setEntryType(event.target.value as JournalType)}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm"
            >
              <option value="deploy">Deploy</option>
              <option value="validate">Validate</option>
              <option value="incident">Incident</option>
              <option value="note">Note</option>
            </select>
          </label>
          <label className="grid gap-1 text-sm text-slate-700" htmlFor="entry-message">
            Message
            <textarea
              id="entry-message"
              value={message}
              onChange={(event) => setMessage(event.target.value)}
              rows={4}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm"
              placeholder="Describe what changed, what was validated, or what is blocked."
            />
          </label>
          <button
            type="submit"
            disabled={saving}
            className="w-fit rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
          >
            {saving ? 'Saving...' : 'Save Entry'}
          </button>
        </form>
        {error && (
          <p className="mt-3 rounded-md border border-rose-300 bg-rose-50 px-3 py-2 text-sm text-rose-700">{error}</p>
        )}
      </section>

      <section className="space-y-3">
        {entries.map((entry) => (
          <article key={entry.id} className="panel rounded-xl p-4">
            <div className="flex flex-wrap items-center gap-2">
              <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${typeStyles[entry.type]}`}>
                {entry.type}
              </span>
              <span className="text-xs text-slate-500">{formatDate(entry.createdAt)}</span>
            </div>
            <p className="mt-2 text-sm text-slate-700">{entry.message}</p>
          </article>
        ))}
      </section>
    </div>
  );
}
