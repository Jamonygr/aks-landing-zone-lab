import { NextResponse } from 'next/server';
import { createLabJournalEntry, getLabJournal } from '@/lib/lab';

export const dynamic = 'force-dynamic';

function parseLimit(rawLimit: string | null): number {
  if (!rawLimit) return 20;
  const parsed = Number(rawLimit);
  if (!Number.isInteger(parsed) || parsed <= 0) return 20;
  return Math.min(parsed, 100);
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = parseLimit(searchParams.get('limit'));
  const entries = await getLabJournal(limit);
  return NextResponse.json({ entries });
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as { type?: string; message?: string };
    if (!body.type || !body.message) {
      return NextResponse.json(
        { error: 'type and message are required' },
        { status: 400 },
      );
    }

    const entry = await createLabJournalEntry({
      type: body.type as 'deploy' | 'validate' | 'incident' | 'note',
      message: body.message,
    });
    return NextResponse.json({ entry }, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to create journal entry';
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
