import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  const checks: Record<string, string> = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: `${process.uptime().toFixed(0)}s`,
    node_env: process.env.NODE_ENV || 'unknown',
  };

  // Check SQL connectivity
  try {
    if (process.env.SQL_CONNECTION_STRING || process.env.SQL_SERVER_FQDN) {
      const { getSqlPool } = await import('@/lib/sql');
      const pool = await getSqlPool();
      await pool.request().query('SELECT 1');
      checks.sql = 'connected';
    } else {
      checks.sql = 'not_configured';
    }
  } catch {
    checks.sql = 'error';
    checks.status = 'degraded';
  }

  const statusCode = checks.status === 'healthy' ? 200 : 503;
  return NextResponse.json(checks, { status: statusCode });
}
