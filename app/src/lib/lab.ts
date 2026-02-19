import sql from 'mssql';
import { getSqlPool } from '@/lib/sql';

export type LabModuleStatus = 'planned' | 'in_progress' | 'blocked' | 'completed';
export type CheckpointStatus = 'todo' | 'done';
export type JournalType = 'deploy' | 'validate' | 'incident' | 'note';

export interface LabCheckpoint {
  id: number;
  moduleId: number;
  title: string;
  status: CheckpointStatus;
  evidence: string;
  updatedAt: Date;
}

export interface LabModule {
  id: number;
  code: string;
  title: string;
  objective: string;
  owner: string;
  status: LabModuleStatus;
  sortOrder: number;
  updatedAt: Date;
  checkpoints: LabCheckpoint[];
}

export interface LabJournalEntry {
  id: number;
  type: JournalType;
  message: string;
  createdAt: Date;
}

export interface LabOverview {
  totalModules: number;
  completedModules: number;
  blockedModules: number;
  totalCheckpoints: number;
  completedCheckpoints: number;
  completionPercent: number;
}

export interface CreateJournalInput {
  type: JournalType;
  message: string;
}

interface ModuleRecord {
  id: number;
  code: string;
  title: string;
  objective: string;
  owner: string;
  status: string;
  sortOrder: number;
  updatedAt: Date;
}

interface CheckpointRecord {
  id: number;
  moduleId: number;
  title: string;
  status: string;
  evidence: string;
  updatedAt: Date;
}

const moduleStatuses: LabModuleStatus[] = ['planned', 'in_progress', 'blocked', 'completed'];
const checkpointStatuses: CheckpointStatus[] = ['todo', 'done'];
const journalTypes: JournalType[] = ['deploy', 'validate', 'incident', 'note'];

let schemaPromise: Promise<void> | null = null;

const fallbackModules: LabModule[] = [
  {
    id: 1,
    code: 'LZ-NET',
    title: 'Networking Foundation',
    objective: 'Validate hub-spoke topology, private DNS links, and AKS subnet routing.',
    owner: 'Platform Team',
    status: 'completed',
    sortOrder: 1,
    updatedAt: new Date('2026-02-15T15:40:00Z'),
    checkpoints: [
      {
        id: 101,
        moduleId: 1,
        title: 'Hub and spoke VNets peered in both directions',
        status: 'done',
        evidence: 'terraform output vnet_peerings',
        updatedAt: new Date('2026-02-15T14:20:00Z'),
      },
      {
        id: 102,
        moduleId: 1,
        title: 'Private DNS zone linked to spoke VNet',
        status: 'done',
        evidence: 'az network private-dns link vnet list',
        updatedAt: new Date('2026-02-15T14:45:00Z'),
      },
    ],
  },
  {
    id: 2,
    code: 'AKS-BASE',
    title: 'AKS Baseline',
    objective: 'Deploy AKS cluster, node pools, and baseline policies through Terraform.',
    owner: 'Platform Team',
    status: 'in_progress',
    sortOrder: 2,
    updatedAt: new Date('2026-02-16T11:30:00Z'),
    checkpoints: [
      {
        id: 201,
        moduleId: 2,
        title: 'Cluster deployed with Azure CNI Overlay',
        status: 'done',
        evidence: 'kubectl get nodes -o wide',
        updatedAt: new Date('2026-02-16T09:10:00Z'),
      },
      {
        id: 202,
        moduleId: 2,
        title: 'System and workload node pools labeled',
        status: 'todo',
        evidence: 'Pending pool taint review',
        updatedAt: new Date('2026-02-16T11:20:00Z'),
      },
      {
        id: 203,
        moduleId: 2,
        title: 'Cluster autoscaler min/max tuned',
        status: 'todo',
        evidence: 'Need load profile from sample apps',
        updatedAt: new Date('2026-02-16T11:30:00Z'),
      },
    ],
  },
  {
    id: 3,
    code: 'IDENTITY',
    title: 'Identity and Secrets',
    objective: 'Enable workload identity and Key Vault CSI integration for workloads.',
    owner: 'Security Team',
    status: 'planned',
    sortOrder: 3,
    updatedAt: new Date('2026-02-17T08:15:00Z'),
    checkpoints: [
      {
        id: 301,
        moduleId: 3,
        title: 'OIDC issuer enabled and validated',
        status: 'todo',
        evidence: 'Not started',
        updatedAt: new Date('2026-02-17T08:15:00Z'),
      },
      {
        id: 302,
        moduleId: 3,
        title: 'Federated credential created for app namespace',
        status: 'todo',
        evidence: 'Not started',
        updatedAt: new Date('2026-02-17T08:15:00Z'),
      },
    ],
  },
  {
    id: 4,
    code: 'OBS',
    title: 'Observability Stack',
    objective: 'Collect logs/metrics and expose a focused dashboard for lab health.',
    owner: 'SRE Team',
    status: 'blocked',
    sortOrder: 4,
    updatedAt: new Date('2026-02-18T04:05:00Z'),
    checkpoints: [
      {
        id: 401,
        moduleId: 4,
        title: 'Prometheus scrape config applied',
        status: 'done',
        evidence: 'targets up in /api/metrics',
        updatedAt: new Date('2026-02-17T20:50:00Z'),
      },
      {
        id: 402,
        moduleId: 4,
        title: 'Grafana dashboard imported',
        status: 'todo',
        evidence: 'Blocked by admin role assignment',
        updatedAt: new Date('2026-02-18T04:05:00Z'),
      },
    ],
  },
];

const fallbackJournal: LabJournalEntry[] = [
  {
    id: 1,
    type: 'deploy',
    message: 'Applied Terraform for base networking and confirmed spoke connectivity.',
    createdAt: new Date('2026-02-15T16:00:00Z'),
  },
  {
    id: 2,
    type: 'validate',
    message: 'Validated cluster API reachability and node registration from jump host.',
    createdAt: new Date('2026-02-16T10:20:00Z'),
  },
  {
    id: 3,
    type: 'incident',
    message: 'Monitoring rollout paused: missing `Monitoring Metrics Publisher` role on workspace.',
    createdAt: new Date('2026-02-18T04:10:00Z'),
  },
];

let fallbackJournalId = fallbackJournal.length + 1;

function isModuleStatus(value: string): value is LabModuleStatus {
  return moduleStatuses.includes(value as LabModuleStatus);
}

function isCheckpointStatus(value: string): value is CheckpointStatus {
  return checkpointStatuses.includes(value as CheckpointStatus);
}

function isJournalType(value: string): value is JournalType {
  return journalTypes.includes(value as JournalType);
}

function mapModuleRecord(record: ModuleRecord, checkpoints: LabCheckpoint[]): LabModule {
  return {
    id: record.id,
    code: record.code,
    title: record.title,
    objective: record.objective,
    owner: record.owner,
    status: isModuleStatus(record.status) ? record.status : 'planned',
    sortOrder: record.sortOrder,
    updatedAt: new Date(record.updatedAt),
    checkpoints,
  };
}

function mapCheckpointRecord(record: CheckpointRecord): LabCheckpoint {
  return {
    id: record.id,
    moduleId: record.moduleId,
    title: record.title,
    status: isCheckpointStatus(record.status) ? record.status : 'todo',
    evidence: record.evidence,
    updatedAt: new Date(record.updatedAt),
  };
}

function cloneFallbackModules(): LabModule[] {
  return fallbackModules.map((module) => ({
    ...module,
    updatedAt: new Date(module.updatedAt),
    checkpoints: module.checkpoints.map((checkpoint) => ({
      ...checkpoint,
      updatedAt: new Date(checkpoint.updatedAt),
    })),
  }));
}

function cloneFallbackJournal(limit?: number): LabJournalEntry[] {
  const sorted = [...fallbackJournal].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  const selected = typeof limit === 'number' ? sorted.slice(0, limit) : sorted;
  return selected.map((entry) => ({ ...entry, createdAt: new Date(entry.createdAt) }));
}

async function ensureSchema(pool: sql.ConnectionPool): Promise<void> {
  if (!schemaPromise) {
    schemaPromise = (async () => {
      await pool.request().query(`
        IF OBJECT_ID(N'dbo.lab_modules', N'U') IS NULL
        BEGIN
          CREATE TABLE dbo.lab_modules (
            id INT IDENTITY(1,1) PRIMARY KEY,
            code NVARCHAR(32) NOT NULL UNIQUE,
            title NVARCHAR(200) NOT NULL,
            objective NVARCHAR(400) NOT NULL,
            owner_name NVARCHAR(120) NOT NULL,
            status NVARCHAR(20) NOT NULL,
            sort_order INT NOT NULL,
            updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
          );
        END;

        IF OBJECT_ID(N'dbo.lab_checkpoints', N'U') IS NULL
        BEGIN
          CREATE TABLE dbo.lab_checkpoints (
            id INT IDENTITY(1,1) PRIMARY KEY,
            module_id INT NOT NULL,
            title NVARCHAR(220) NOT NULL,
            status NVARCHAR(20) NOT NULL,
            evidence NVARCHAR(300) NOT NULL,
            sort_order INT NOT NULL,
            updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_lab_checkpoints_module FOREIGN KEY (module_id) REFERENCES dbo.lab_modules(id)
          );
        END;

        IF OBJECT_ID(N'dbo.lab_journal_entries', N'U') IS NULL
        BEGIN
          CREATE TABLE dbo.lab_journal_entries (
            id INT IDENTITY(1,1) PRIMARY KEY,
            entry_type NVARCHAR(20) NOT NULL,
            message NVARCHAR(500) NOT NULL,
            created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
          );
        END;
      `);

      await pool.request().query(`
        IF NOT EXISTS (SELECT 1 FROM dbo.lab_modules)
        BEGIN
          INSERT INTO dbo.lab_modules (code, title, objective, owner_name, status, sort_order)
          VALUES
            (N'LZ-NET', N'Networking Foundation', N'Validate hub-spoke topology, private DNS links, and AKS subnet routing.', N'Platform Team', N'completed', 1),
            (N'AKS-BASE', N'AKS Baseline', N'Deploy AKS cluster, node pools, and baseline policies through Terraform.', N'Platform Team', N'in_progress', 2),
            (N'IDENTITY', N'Identity and Secrets', N'Enable workload identity and Key Vault CSI integration for workloads.', N'Security Team', N'planned', 3),
            (N'OBS', N'Observability Stack', N'Collect logs/metrics and expose a focused dashboard for lab health.', N'SRE Team', N'blocked', 4);
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.lab_checkpoints)
        BEGIN
          INSERT INTO dbo.lab_checkpoints (module_id, title, status, evidence, sort_order)
          SELECT m.id, v.title, v.status, v.evidence, v.sort_order
          FROM (
            VALUES
              (N'LZ-NET', N'Hub and spoke VNets peered in both directions', N'done', N'terraform output vnet_peerings', 1),
              (N'LZ-NET', N'Private DNS zone linked to spoke VNet', N'done', N'az network private-dns link vnet list', 2),
              (N'AKS-BASE', N'Cluster deployed with Azure CNI Overlay', N'done', N'kubectl get nodes -o wide', 1),
              (N'AKS-BASE', N'System and workload node pools labeled', N'todo', N'Pending pool taint review', 2),
              (N'AKS-BASE', N'Cluster autoscaler min/max tuned', N'todo', N'Need load profile from sample apps', 3),
              (N'IDENTITY', N'OIDC issuer enabled and validated', N'todo', N'Not started', 1),
              (N'IDENTITY', N'Federated credential created for app namespace', N'todo', N'Not started', 2),
              (N'OBS', N'Prometheus scrape config applied', N'done', N'targets up in /api/metrics', 1),
              (N'OBS', N'Grafana dashboard imported', N'todo', N'Blocked by admin role assignment', 2)
          ) AS v(code, title, status, evidence, sort_order)
          INNER JOIN dbo.lab_modules AS m ON m.code = v.code;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.lab_journal_entries)
        BEGIN
          INSERT INTO dbo.lab_journal_entries (entry_type, message)
          VALUES
            (N'deploy', N'Applied Terraform for base networking and confirmed spoke connectivity.'),
            (N'validate', N'Validated cluster API reachability and node registration from jump host.'),
            (N'incident', N'Monitoring rollout paused: missing Monitoring Metrics Publisher role on workspace.');
        END;
      `);
    })();
  }

  return schemaPromise;
}

async function withSql<T>(handler: (pool: sql.ConnectionPool) => Promise<T>): Promise<T> {
  const pool = await getSqlPool();
  await ensureSchema(pool);
  return handler(pool);
}

function computeOverview(modules: LabModule[]): LabOverview {
  const totalModules = modules.length;
  const completedModules = modules.filter((module) => module.status === 'completed').length;
  const blockedModules = modules.filter((module) => module.status === 'blocked').length;
  const checkpoints = modules.flatMap((module) => module.checkpoints);
  const totalCheckpoints = checkpoints.length;
  const completedCheckpoints = checkpoints.filter((checkpoint) => checkpoint.status === 'done').length;
  const completionPercent = totalCheckpoints === 0 ? 0 : Math.round((completedCheckpoints / totalCheckpoints) * 100);

  return {
    totalModules,
    completedModules,
    blockedModules,
    totalCheckpoints,
    completedCheckpoints,
    completionPercent,
  };
}

async function getModulesFromSql(pool: sql.ConnectionPool): Promise<LabModule[]> {
  const modulesResult = await pool.request().query<ModuleRecord>(`
    SELECT
      id,
      code,
      title,
      objective,
      owner_name AS owner,
      status,
      sort_order AS sortOrder,
      updated_at AS updatedAt
    FROM dbo.lab_modules
    ORDER BY sort_order ASC, id ASC;
  `);

  const checkpointsResult = await pool.request().query<CheckpointRecord>(`
    SELECT
      id,
      module_id AS moduleId,
      title,
      status,
      evidence,
      updated_at AS updatedAt
    FROM dbo.lab_checkpoints
    ORDER BY module_id ASC, sort_order ASC, id ASC;
  `);

  const checkpointsByModule = new Map<number, LabCheckpoint[]>();
  for (const record of checkpointsResult.recordset) {
    const mapped = mapCheckpointRecord(record);
    const existing = checkpointsByModule.get(mapped.moduleId) || [];
    existing.push(mapped);
    checkpointsByModule.set(mapped.moduleId, existing);
  }

  return modulesResult.recordset.map((record) => mapModuleRecord(record, checkpointsByModule.get(record.id) || []));
}

function normalizeModuleStatus(value: string): LabModuleStatus {
  if (!isModuleStatus(value)) {
    throw new Error('Invalid module status');
  }
  return value;
}

function normalizeCheckpointStatus(value: string): CheckpointStatus {
  if (!isCheckpointStatus(value)) {
    throw new Error('Invalid checkpoint status');
  }
  return value;
}

function normalizeJournalType(value: string): JournalType {
  if (!isJournalType(value)) {
    throw new Error('Invalid journal type');
  }
  return value;
}

export async function getLabModules(): Promise<LabModule[]> {
  try {
    return await withSql((pool) => getModulesFromSql(pool));
  } catch {
    return cloneFallbackModules().sort((a, b) => a.sortOrder - b.sortOrder);
  }
}

export async function getLabOverview(): Promise<LabOverview> {
  const modules = await getLabModules();
  return computeOverview(modules);
}

export async function updateLabModuleStatus(moduleId: number, status: string): Promise<LabModule | null> {
  const normalizedStatus = normalizeModuleStatus(status);

  try {
    return await withSql(async (pool) => {
      await pool.request()
        .input('moduleId', sql.Int, moduleId)
        .input('status', sql.NVarChar(20), normalizedStatus)
        .query(`
          UPDATE dbo.lab_modules
          SET status = @status, updated_at = SYSUTCDATETIME()
          WHERE id = @moduleId;
        `);

      const modules = await getModulesFromSql(pool);
      return modules.find((module) => module.id === moduleId) || null;
    });
  } catch {
    const target = fallbackModules.find((module) => module.id === moduleId);
    if (!target) return null;
    target.status = normalizedStatus;
    target.updatedAt = new Date();
    return cloneFallbackModules().find((module) => module.id === moduleId) || null;
  }
}

export async function updateCheckpointStatus(checkpointId: number, status: string): Promise<LabCheckpoint | null> {
  const normalizedStatus = normalizeCheckpointStatus(status);

  try {
    return await withSql(async (pool) => {
      await pool.request()
        .input('checkpointId', sql.Int, checkpointId)
        .input('status', sql.NVarChar(20), normalizedStatus)
        .query(`
          UPDATE dbo.lab_checkpoints
          SET status = @status, updated_at = SYSUTCDATETIME()
          WHERE id = @checkpointId;
        `);

      const result = await pool.request()
        .input('checkpointId', sql.Int, checkpointId)
        .query<CheckpointRecord>(`
          SELECT
            id,
            module_id AS moduleId,
            title,
            status,
            evidence,
            updated_at AS updatedAt
          FROM dbo.lab_checkpoints
          WHERE id = @checkpointId;
        `);
      const record = result.recordset[0];
      return record ? mapCheckpointRecord(record) : null;
    });
  } catch {
    for (const labModule of fallbackModules) {
      const checkpoint = labModule.checkpoints.find((item) => item.id === checkpointId);
      if (checkpoint) {
        checkpoint.status = normalizedStatus;
        checkpoint.updatedAt = new Date();
        labModule.updatedAt = new Date();
        return cloneFallbackModules()
          .flatMap((item) => item.checkpoints)
          .find((item) => item.id === checkpointId) || null;
      }
    }
    return null;
  }
}

export async function getLabJournal(limit: number = 20): Promise<LabJournalEntry[]> {
  try {
    return await withSql(async (pool) => {
      const result = await pool.request()
        .input('limit', sql.Int, limit)
        .query<{
          id: number;
          type: string;
          message: string;
          createdAt: Date;
        }>(`
          SELECT TOP (@limit)
            id,
            entry_type AS type,
            message,
            created_at AS createdAt
          FROM dbo.lab_journal_entries
          ORDER BY created_at DESC, id DESC;
        `);

      return result.recordset.map((entry) => ({
        id: entry.id,
        type: isJournalType(entry.type) ? entry.type : 'note',
        message: entry.message,
        createdAt: new Date(entry.createdAt),
      }));
    });
  } catch {
    return cloneFallbackJournal(limit);
  }
}

export async function createLabJournalEntry(input: CreateJournalInput): Promise<LabJournalEntry> {
  const type = normalizeJournalType(input.type);
  const message = input.message.trim();
  if (!message) {
    throw new Error('Message is required');
  }

  try {
    return await withSql(async (pool) => {
      const result = await pool.request()
        .input('type', sql.NVarChar(20), type)
        .input('message', sql.NVarChar(500), message)
        .query<{
          id: number;
          type: string;
          message: string;
          createdAt: Date;
        }>(`
          DECLARE @inserted TABLE (
            id INT,
            type NVARCHAR(20),
            message NVARCHAR(500),
            createdAt DATETIME2
          );

          INSERT INTO dbo.lab_journal_entries (entry_type, message)
          OUTPUT INSERTED.id, INSERTED.entry_type, INSERTED.message, INSERTED.created_at
            INTO @inserted (id, type, message, createdAt)
          VALUES (@type, @message);

          SELECT id, type, message, createdAt FROM @inserted;
        `);

      const row = result.recordset[0];
      if (!row) {
        throw new Error('Failed to create entry');
      }

      return {
        id: row.id,
        type: isJournalType(row.type) ? row.type : 'note',
        message: row.message,
        createdAt: new Date(row.createdAt),
      };
    });
  } catch {
    const newEntry: LabJournalEntry = {
      id: fallbackJournalId,
      type,
      message,
      createdAt: new Date(),
    };
    fallbackJournalId += 1;
    fallbackJournal.push(newEntry);
    return { ...newEntry, createdAt: new Date(newEntry.createdAt) };
  }
}
