import sql from 'mssql';

let pool: sql.ConnectionPool | null = null;

export async function getSqlPool(): Promise<sql.ConnectionPool> {
  if (pool) return pool;

  const connectionString = process.env.SQL_CONNECTION_STRING;
  const server = process.env.SQL_SERVER_FQDN;
  const database = process.env.SQL_DATABASE_NAME || 'learninghub';

  if (connectionString) {
    const connectionPool = new sql.ConnectionPool(connectionString);
    pool = await connectionPool.connect();
  } else if (server) {
    const config: sql.config = {
      server,
      database,
      authentication: {
        type: 'azure-active-directory-default',
        options: {},
      },
      options: {
        encrypt: true,
        trustServerCertificate: false,
      },
    };

    const connectionPool = new sql.ConnectionPool(config);
    pool = await connectionPool.connect();
  } else {
    throw new Error('SQL_CONNECTION_STRING or SQL_SERVER_FQDN must be set');
  }

  return pool;
}

export interface Post {
  id: number;
  title: string;
  slug: string;
  content: string;
  category: string;
  created_at: Date;
}

export interface Exercise {
  id: number;
  title: string;
  description: string;
  difficulty: string;
  completed: boolean;
}

export interface Project {
  id: number;
  title: string;
  description: string;
  tech_stack: string;
  url: string;
}

export interface Activity {
  id: number;
  userId: string;
  type: string;
  description: string;
  metadata?: string;
  timestamp: Date;
}

export interface Comment {
  id: number;
  postId: string;
  author: string;
  content: string;
  timestamp: Date;
}

export async function getPosts(): Promise<Post[]> {
  try {
    const pool = await getSqlPool();
    const result = await pool.request().query('SELECT * FROM posts ORDER BY created_at DESC');
    return result.recordset;
  } catch {
    return getSamplePosts();
  }
}

export async function getPostBySlug(slug: string): Promise<Post | null> {
  try {
    const pool = await getSqlPool();
    const result = await pool.request()
      .input('slug', sql.VarChar, slug)
      .query('SELECT * FROM posts WHERE slug = @slug');
    return result.recordset[0] || null;
  } catch {
    return getSamplePosts().find(p => p.slug === slug) || null;
  }
}

export async function getExercises(): Promise<Exercise[]> {
  try {
    const pool = await getSqlPool();
    const result = await pool.request().query('SELECT * FROM exercises ORDER BY id');
    return result.recordset;
  } catch {
    return getSampleExercises();
  }
}

export async function getProjects(): Promise<Project[]> {
  try {
    const pool = await getSqlPool();
    const result = await pool.request().query('SELECT * FROM projects ORDER BY id');
    return result.recordset;
  } catch {
    return getSampleProjects();
  }
}

export async function getActivities(limit: number = 20): Promise<Activity[]> {
  try {
    const pool = await getSqlPool();
    const result = await pool.request()
      .input('limit', sql.Int, limit)
      .query('SELECT TOP (@limit) * FROM activities ORDER BY timestamp DESC');
    return result.recordset;
  } catch {
    return getSampleActivities();
  }
}

export async function addActivity(activity: { userId: string; type: string; description: string; metadata?: Record<string, unknown> }): Promise<void> {
  try {
    const pool = await getSqlPool();
    await pool.request()
      .input('userId', sql.VarChar, activity.userId)
      .input('type', sql.VarChar, activity.type)
      .input('description', sql.NVarChar, activity.description)
      .input('metadata', sql.NVarChar, activity.metadata ? JSON.stringify(activity.metadata) : null)
      .query('INSERT INTO activities (userId, type, description, metadata) VALUES (@userId, @type, @description, @metadata)');
  } catch (err) {
    console.error('Failed to add activity:', err);
  }
}

export async function getComments(postId: string): Promise<Comment[]> {
  try {
    const pool = await getSqlPool();
    const result = await pool.request()
      .input('postId', sql.VarChar, postId)
      .query('SELECT * FROM comments WHERE postId = @postId ORDER BY timestamp DESC');
    return result.recordset;
  } catch {
    return [];
  }
}

export async function addComment(comment: { postId: string; author: string; content: string }): Promise<void> {
  try {
    const pool = await getSqlPool();
    await pool.request()
      .input('postId', sql.VarChar, comment.postId)
      .input('author', sql.NVarChar, comment.author)
      .input('content', sql.NVarChar, comment.content)
      .query('INSERT INTO comments (postId, author, content) VALUES (@postId, @author, @content)');
  } catch (err) {
    console.error('Failed to add comment:', err);
  }
}

// Fallback sample data when DB is unavailable
function getSampleActivities(): Activity[] {
  return [
    { id: 1, userId: 'demo', type: 'page_view', description: 'Viewed AKS Networking post', timestamp: new Date() },
    { id: 2, userId: 'demo', type: 'exercise_complete', description: 'Completed Deploy AKS Cluster exercise', timestamp: new Date() },
  ];
}

function getSamplePosts(): Post[] {
  return [
    { id: 1, title: 'Understanding AKS Networking', slug: 'aks-networking', content: 'Azure CNI Overlay provides pod networking with a flat address space. Combined with Calico network policies, you get enterprise-grade network segmentation. This post covers hub-spoke topology, VNet peering, and how pods communicate across subnets.', category: 'Networking', created_at: new Date('2025-12-01') },
    { id: 2, title: 'Workload Identity Deep Dive', slug: 'workload-identity', content: 'Workload Identity eliminates the need for storing credentials. Using OIDC federation, your Kubernetes service accounts can authenticate directly to Azure services like SQL Database. This article walks through the setup with federated identity credentials.', category: 'Security', created_at: new Date('2025-12-15') },
    { id: 3, title: 'Cost Optimization on AKS', slug: 'cost-optimization', content: 'Running AKS cost-effectively requires the right VM sizes, autoscaling configuration, and resource management. Learn about B-series VMs for dev/test, cluster autoscaler tuning, and how to use Azure Cost Management budgets and alerts.', category: 'Operations', created_at: new Date('2026-01-05') },
    { id: 4, title: 'Private Endpoints for Data Services', slug: 'private-endpoints', content: 'Private endpoints bring Azure PaaS services into your VNet. This post covers setting up private endpoints for Azure SQL with private DNS zones, ensuring your data never traverses the public internet.', category: 'Networking', created_at: new Date('2026-01-20') },
    { id: 5, title: 'Hub-Spoke Landing Zones with Terraform', slug: 'landing-zones-terraform', content: 'Enterprise AKS deployments use landing zone patterns to separate concerns. This article explains how to structure Terraform modules for networking, security, identity, management, and data landing zones with proper dependency management.', category: 'Infrastructure', created_at: new Date('2026-02-01') },
  ];
}

function getSampleExercises(): Exercise[] {
  return [
    { id: 1, title: 'Deploy AKS Cluster', description: 'Create an AKS cluster with Azure CNI Overlay and Calico network policies using Terraform.', difficulty: 'Beginner', completed: false },
    { id: 2, title: 'Configure Hub-Spoke Networking', description: 'Set up hub-spoke VNet topology with peering, NSGs, and route tables.', difficulty: 'Intermediate', completed: false },
    { id: 3, title: 'Set Up Workload Identity', description: 'Configure OIDC issuer, managed identity, and federated credentials for passwordless Azure access.', difficulty: 'Intermediate', completed: false },
    { id: 4, title: 'Deploy NGINX Ingress', description: 'Install NGINX ingress controller via Helm and expose a web application.', difficulty: 'Beginner', completed: false },
    { id: 5, title: 'Configure Key Vault CSI', description: 'Deploy Secrets Store CSI Driver and mount Azure Key Vault secrets into pods.', difficulty: 'Intermediate', completed: false },
    { id: 6, title: 'Implement Network Policies', description: 'Create Calico network policies for default-deny and selective allow rules.', difficulty: 'Intermediate', completed: false },
    { id: 7, title: 'Set Up Monitoring Stack', description: 'Configure Container Insights, Prometheus scraping, and Grafana dashboards.', difficulty: 'Advanced', completed: false },
    { id: 8, title: 'Add Private Endpoints', description: 'Create private endpoints for Azure SQL with DNS zone integration.', difficulty: 'Advanced', completed: false },
    { id: 9, title: 'Configure HPA Autoscaling', description: 'Set up Horizontal Pod Autoscaler with CPU and custom metrics.', difficulty: 'Intermediate', completed: false },
    { id: 10, title: 'Production Hardening', description: 'Apply pod security standards, resource quotas, limit ranges, and Azure Policy.', difficulty: 'Advanced', completed: false },
  ];
}

function getSampleProjects(): Project[] {
  return [
    { id: 1, title: 'AKS Landing Zone Lab', description: 'Enterprise AKS environment with hub-spoke networking, 6 landing zones, and 20+ Terraform modules.', tech_stack: 'Terraform, AKS, Azure CNI, Calico, Helm', url: 'https://github.com/Jamonygr/aks-landing-zone-lab' },
    { id: 2, title: 'Learning Hub Web App', description: 'Full-stack Next.js application running on AKS with Azure SQL backend.', tech_stack: 'Next.js, TypeScript, Azure SQL, Docker', url: '#' },
    { id: 3, title: 'Monitoring & Observability', description: 'End-to-end observability with Container Insights, Prometheus, Grafana, and structured logging.', tech_stack: 'Prometheus, Grafana, Log Analytics, Container Insights', url: '#' },
  ];
}
