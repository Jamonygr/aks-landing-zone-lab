import { NextResponse } from 'next/server';
import { getLabOverview, updateCheckpointStatus } from '@/lib/lab';

export const dynamic = 'force-dynamic';

function parseId(id: string): number | null {
  const parsed = Number(id);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    return null;
  }
  return parsed;
}

export async function PATCH(
  request: Request,
  { params }: { params: { id: string } },
) {
  const checkpointId = parseId(params.id);
  if (!checkpointId) {
    return NextResponse.json({ error: 'Invalid checkpoint id' }, { status: 400 });
  }

  try {
    const body = (await request.json()) as { status?: string };
    if (!body.status) {
      return NextResponse.json({ error: 'status is required' }, { status: 400 });
    }

    const updated = await updateCheckpointStatus(checkpointId, body.status);
    if (!updated) {
      return NextResponse.json({ error: 'Checkpoint not found' }, { status: 404 });
    }

    const overview = await getLabOverview();
    return NextResponse.json({ checkpoint: updated, overview });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update checkpoint status';
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
