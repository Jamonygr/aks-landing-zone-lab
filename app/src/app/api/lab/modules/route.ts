import { NextResponse } from 'next/server';
import { getLabModules, getLabOverview } from '@/lib/lab';

export const dynamic = 'force-dynamic';

export async function GET() {
  const [modules, overview] = await Promise.all([
    getLabModules(),
    getLabOverview(),
  ]);

  return NextResponse.json({
    modules,
    overview,
  });
}
