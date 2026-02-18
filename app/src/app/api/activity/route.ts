import { NextResponse } from 'next/server';
import { getActivities, addActivity } from '@/lib/sql';

export const dynamic = 'force-dynamic';

export async function GET() {
  const activities = await getActivities(20);
  return NextResponse.json(activities);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    await addActivity({
      userId: body.userId || 'anonymous',
      type: body.type || 'page_view',
      description: body.description || '',
      metadata: body.metadata,
    });
    return NextResponse.json({ success: true }, { status: 201 });
  } catch {
    return NextResponse.json({ error: 'Failed to create activity' }, { status: 500 });
  }
}
