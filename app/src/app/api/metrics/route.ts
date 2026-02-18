import { NextResponse } from 'next/server';
import client from 'prom-client';

// Initialize default metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Custom counters
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'path'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register],
});

const dbQueryDuration = new client.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['db_type', 'operation'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
  registers: [register],
});

// Simulate some metrics
httpRequestsTotal.inc({ method: 'GET', path: '/', status: '200' }, Math.floor(Math.random() * 100));
httpRequestsTotal.inc({ method: 'GET', path: '/blog', status: '200' }, Math.floor(Math.random() * 50));
httpRequestsTotal.inc({ method: 'GET', path: '/labs', status: '200' }, Math.floor(Math.random() * 30));
activeConnections.set(Math.floor(Math.random() * 10) + 1);

export const dynamic = 'force-dynamic';

export async function GET() {
  const metrics = await register.metrics();
  return new NextResponse(metrics, {
    headers: { 'Content-Type': register.contentType },
  });
}
