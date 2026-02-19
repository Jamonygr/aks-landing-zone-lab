import { NextResponse } from 'next/server';
import { getLabJournal, getLabOverview } from '@/lib/lab';

export const dynamic = 'force-dynamic';

export async function GET() {
  const [overview, journal] = await Promise.all([
    getLabOverview(),
    getLabJournal(5),
  ]);

  return NextResponse.json({
    overview,
    recentJournal: journal,
  });
}
