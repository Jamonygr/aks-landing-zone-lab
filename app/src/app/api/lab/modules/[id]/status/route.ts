import { NextResponse } from 'next/server';
import { getLabOverview, updateLabModuleStatus } from '@/lib/lab';

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
  const moduleId = parseId(params.id);
  if (!moduleId) {
    return NextResponse.json({ error: 'Invalid module id' }, { status: 400 });
  }

  try {
    const body = (await request.json()) as { status?: string };
    if (!body.status) {
      return NextResponse.json({ error: 'status is required' }, { status: 400 });
    }

    const updated = await updateLabModuleStatus(moduleId, body.status);
    if (!updated) {
      return NextResponse.json({ error: 'Module not found' }, { status: 404 });
    }

    const overview = await getLabOverview();
    return NextResponse.json({ module: updated, overview });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update module status';
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
