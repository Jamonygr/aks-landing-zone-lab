export const TOTAL_WIKI_PAGES = 1000;
export const PAGES_PER_MODULE = 20;
export const TOTAL_MODULES = TOTAL_WIKI_PAGES / PAGES_PER_MODULE;

const categories = [
  {
    key: 'foundation',
    shortLabel: 'Foundation',
    fullLabel: 'Foundation Baseline',
    accent: 'sky',
  },
  {
    key: 'network',
    shortLabel: 'Network',
    fullLabel: 'Network Validation',
    accent: 'teal',
  },
  {
    key: 'security',
    shortLabel: 'Security',
    fullLabel: 'Security Hardening',
    accent: 'amber',
  },
  {
    key: 'workloads',
    shortLabel: 'Workloads',
    fullLabel: 'Workload Reliability',
    accent: 'indigo',
  },
  {
    key: 'operations',
    shortLabel: 'Operations',
    fullLabel: 'Operations Drill',
    accent: 'rose',
  },
] as const;

const moduleThemes = [
  'Platform Bootstrap',
  'Core Cluster Networking',
  'Private Access and DNS',
  'Identity Federation',
  'Secret Distribution',
  'Policy Guardrails',
  'Storage Path Validation',
  'Ingress Exposure',
  'Autoscaling Signals',
  'Monitoring Baselines',
  'Release Validation',
  'Resilience and Recovery',
] as const;

const detailFocuses = [
  'control plane',
  'node pools',
  'service mesh edge',
  'private endpoint routing',
  'identity boundaries',
  'policy compliance',
  'application reliability',
  'incident response',
] as const;

export type WikiCategoryKey = (typeof categories)[number]['key'];
export type WikiAccent = (typeof categories)[number]['accent'];
export type WikiDifficulty = 'Core' | 'Advanced' | 'Expert';

export interface WikiStep {
  id: string;
  title: string;
  description: string;
  command?: string;
  expected: string;
  whyItMatters: string;
}

export interface WikiFailurePattern {
  symptom: string;
  likelyCause: string;
  recovery: string;
}

export interface WikiPageSummary {
  pageNumber: number;
  path: string;
  moduleNumber: number;
  categoryKey: WikiCategoryKey;
  categoryShortLabel: string;
  categoryFullLabel: string;
  categoryAccent: WikiAccent;
  title: string;
  summary: string;
  focusArea: string;
  difficulty: WikiDifficulty;
  estimatedMinutes: number;
}

export interface WikiPage extends WikiPageSummary {
  scenario: string;
  objective: string;
  prerequisites: string[];
  steps: WikiStep[];
  verifications: string[];
  signalsToWatch: string[];
  commonFailures: WikiFailurePattern[];
  notesPrompt: string;
  moduleTheme: string;
  artSeed: number;
}

export interface WikiModuleSummary {
  moduleNumber: number;
  moduleTheme: string;
  pages: WikiPageSummary[];
}

interface PageContext {
  moduleNumber: number;
  pageNumber: number;
  modulePageNumber: number;
  categoryIndex: number;
  categoryKey: WikiCategoryKey;
  moduleTheme: string;
  focusArea: string;
  moduleCycle: number;
}

function getPageIndexInModule(pageNumber: number): number {
  return (pageNumber - 1) % PAGES_PER_MODULE;
}

function getCategoryIndex(pageNumber: number): number {
  return getPageIndexInModule(pageNumber) % categories.length;
}

function getModuleNumber(pageNumber: number): number {
  return Math.floor((pageNumber - 1) / PAGES_PER_MODULE) + 1;
}

function getPagePath(pageNumber: number): string {
  return `/labs/${pageNumber}`;
}

function getDifficulty(moduleNumber: number, categoryIndex: number): WikiDifficulty {
  if (moduleNumber >= 70 || categoryIndex >= 3) return 'Expert';
  if (moduleNumber >= 30) return 'Advanced';
  return 'Core';
}

function getEstimatedMinutes(moduleNumber: number, categoryIndex: number): number {
  const base = 14 + categoryIndex * 2;
  const bonus = Math.floor((moduleNumber - 1) / 10);
  return Math.min(45, base + bonus);
}

function createPageContext(pageNumber: number): PageContext {
  const pageIndexInModule = getPageIndexInModule(pageNumber);
  const categoryIndex = getCategoryIndex(pageNumber);
  const moduleNumber = getModuleNumber(pageNumber);
  const category = categories[categoryIndex];
  const moduleTheme = moduleThemes[(moduleNumber - 1) % moduleThemes.length];
  const focusArea = detailFocuses[(moduleNumber + pageIndexInModule) % detailFocuses.length];
  const moduleCycle = Math.floor((moduleNumber - 1) / moduleThemes.length) + 1;

  return {
    moduleNumber,
    pageNumber,
    modulePageNumber: pageIndexInModule + 1,
    categoryIndex,
    categoryKey: category.key,
    moduleTheme,
    focusArea,
    moduleCycle,
  };
}

function buildSummary(context: PageContext): string {
  const { categoryKey, moduleNumber, moduleTheme, focusArea } = context;
  if (categoryKey === 'foundation') {
    return `Capture a clean baseline for module ${moduleNumber} (${moduleTheme}), focused on ${focusArea}.`;
  }
  if (categoryKey === 'network') {
    return `Run deep network tests for module ${moduleNumber}, validating DNS, ingress, and private routing paths.`;
  }
  if (categoryKey === 'security') {
    return `Validate security boundaries for module ${moduleNumber}: identity, policy, and runtime controls.`;
  }
  if (categoryKey === 'workloads') {
    return `Exercise rollout and reliability checks for module ${moduleNumber}, including scale and telemetry.`;
  }
  return `Execute incident-response drills for module ${moduleNumber} and document recovery outcomes.`;
}

function buildScenario(context: PageContext): string {
  const { moduleNumber, moduleTheme, focusArea, moduleCycle } = context;
  return `You are operating Module ${moduleNumber} in cycle ${moduleCycle}. This module expands ${moduleTheme} with heightened focus on ${focusArea}. Treat this page as an execution-grade runbook: collect evidence, validate outcomes, and record decisions as if this were a production readiness gate.`;
}

function buildObjective(context: PageContext): string {
  const { categoryKey, moduleNumber, focusArea } = context;
  if (categoryKey === 'foundation') {
    return `Establish trusted pre-change signals for module ${moduleNumber}, ensuring ${focusArea} has measurable baselines.`;
  }
  if (categoryKey === 'network') {
    return `Prove network paths for ${focusArea} are deterministic and recoverable during module ${moduleNumber} changes.`;
  }
  if (categoryKey === 'security') {
    return `Confirm least-privilege and policy enforcement around ${focusArea} during module ${moduleNumber}.`;
  }
  if (categoryKey === 'workloads') {
    return `Verify workloads tied to ${focusArea} stay healthy through rollout, restart, and scaling operations.`;
  }
  return `Demonstrate repeatable troubleshooting for ${focusArea} with clear recovery evidence and notes.`;
}

function buildPrerequisites(context: PageContext): string[] {
  const { moduleNumber, moduleTheme, categoryKey } = context;
  const shared = [
    'AKS credentials are current (`az aks get-credentials --overwrite-existing`).',
    'Your active context targets the intended lab cluster.',
    'You can access `lab-apps`, `lab-monitoring`, and ingress namespaces.',
    `Module ${moduleNumber} notes are opened and writable for evidence capture.`,
  ];

  if (categoryKey === 'network') {
    shared.push('Ingress public IP and DNS records are known for test probes.');
  }
  if (categoryKey === 'security') {
    shared.push('Workload identity and Key Vault integration are deployed for this stage.');
  }
  if (categoryKey === 'operations') {
    shared.push(`Rollback plan for ${moduleTheme} is prepared before drill execution.`);
  }
  return shared;
}

function buildSignalsToWatch(context: PageContext): string[] {
  const { categoryKey } = context;
  if (categoryKey === 'foundation') {
    return [
      'Node readiness and scheduling pressure.',
      'Critical deployment availability deltas.',
      'API server responsiveness during baseline capture.',
    ];
  }
  if (categoryKey === 'network') {
    return [
      'Service endpoint population and churn.',
      'DNS lookup latency and NXDOMAIN spikes.',
      'Ingress status code distribution (2xx/4xx/5xx).',
    ];
  }
  if (categoryKey === 'security') {
    return [
      'Unexpected RBAC allows/denies.',
      'Secret mount or token federation errors.',
      'Policy admission denials in target namespaces.',
    ];
  }
  if (categoryKey === 'workloads') {
    return [
      'Rollout progress and unavailable replica counts.',
      'Container restart frequency.',
      'Latency and saturation metrics during load.',
    ];
  }
  return [
    'Time-to-detection from symptom onset.',
    'Time-to-recovery after mitigation action.',
    'Residual warnings/events after drill completion.',
  ];
}

function buildVerifications(context: PageContext): string[] {
  const { categoryKey, moduleNumber } = context;
  if (categoryKey === 'foundation') {
    return [
      `Baseline evidence for module ${moduleNumber} is recorded and timestamped.`,
      'Cluster and namespace health checks completed with no unknown states.',
      'Pre-change deployment inventory is captured.',
    ];
  }
  if (categoryKey === 'network') {
    return [
      'Internal service discovery succeeds from test workloads.',
      'External ingress route serves expected application response.',
      'Private routing and endpoint associations are confirmed.',
    ];
  }
  if (categoryKey === 'security') {
    return [
      'Service account identity bindings are correct.',
      'Policy controls enforce expected restrictions.',
      'Runtime pod security settings align with restricted profile.',
    ];
  }
  if (categoryKey === 'workloads') {
    return [
      'Deployment rollouts complete without regression.',
      'Application health and telemetry remain stable.',
      'Scale behavior matches expected thresholds.',
    ];
  }
  return [
    'Drill scenario executed and recovery completed.',
    'Post-incident validation checks pass.',
    'Lessons learned and follow-up actions are documented.',
  ];
}

function buildFailurePatterns(context: PageContext): WikiFailurePattern[] {
  const { categoryKey } = context;
  if (categoryKey === 'network') {
    return [
      {
        symptom: 'Ingress responds with 502/504 during rollout',
        likelyCause: 'Backend endpoints became empty or readiness never passed',
        recovery: 'Check service endpoints and probe paths; roll back bad deployment if needed.',
      },
      {
        symptom: 'In-cluster DNS lookup intermittently fails',
        likelyCause: 'CoreDNS pressure or policy blocking kube-dns',
        recovery: 'Validate DNS egress policy and CoreDNS pod health in kube-system.',
      },
    ];
  }
  if (categoryKey === 'security') {
    return [
      {
        symptom: 'Workload cannot access Key Vault secret',
        likelyCause: 'Workload identity annotation/client ID mismatch',
        recovery: 'Compare service account annotation, federated credential, and pod env token paths.',
      },
      {
        symptom: 'Unexpected pod admission denial',
        likelyCause: 'Policy assignment conflicts with manifest security context',
        recovery: 'Review denied rule details and update pod security fields explicitly.',
      },
    ];
  }
  if (categoryKey === 'operations') {
    return [
      {
        symptom: 'Recovery step succeeded but errors continue',
        likelyCause: 'Stale config or pending old replicas still serving',
        recovery: 'Confirm rollout completion and verify service endpoints map to new pods only.',
      },
      {
        symptom: 'Incident repeats after temporary mitigation',
        likelyCause: 'Underlying threshold or dependency issue unresolved',
        recovery: 'Capture root cause in notes and create a permanent remediation task.',
      },
    ];
  }
  return [
    {
      symptom: 'Health endpoint degrades while pods remain running',
      likelyCause: 'Dependency check failing (SQL, external endpoint, or identity)',
      recovery: 'Split liveness/readiness as needed and verify dependency-specific telemetry.',
    },
    {
      symptom: 'Rollout stalls with unavailable replicas',
      likelyCause: 'Probe path mismatch or insufficient resource headroom',
      recovery: 'Inspect describe/logs, correct probes, and tune requests/limits.',
    },
  ];
}

function buildNotesPrompt(context: PageContext): string {
  const { moduleNumber, categoryKey, focusArea } = context;
  return `Document module ${moduleNumber} ${categoryKey} results: commands used, evidence collected, decisions made, and next actions for ${focusArea}.`;
}

function buildFoundationSteps(context: PageContext): WikiStep[] {
  const { moduleNumber, pageNumber, moduleTheme, focusArea } = context;
  return [
    {
      id: `p${pageNumber}-s1`,
      title: 'Verify active cluster context and subscription',
      description: 'Ensure all commands target the intended AKS environment before baseline capture.',
      command: 'kubectl config current-context && az account show --query name -o tsv',
      expected: 'Context and subscription align with this lab environment.',
      whyItMatters: 'Prevents accidental changes in the wrong cluster or subscription.',
    },
    {
      id: `p${pageNumber}-s2`,
      title: 'Capture node and runtime baseline',
      description: `Collect node readiness and runtime details tied to ${moduleTheme}.`,
      command: 'kubectl get nodes -o wide',
      expected: 'All required nodes are Ready with expected versions.',
      whyItMatters: 'Establishes baseline system capacity before tests.',
    },
    {
      id: `p${pageNumber}-s3`,
      title: 'Inventory namespace-level resources',
      description: 'List deploy, statefulset, job, and service objects in core lab namespaces.',
      command: 'kubectl get deploy,sts,job,svc -n lab-apps',
      expected: 'Core resources are discoverable and no unexpected objects appear.',
      whyItMatters: 'Creates traceable baseline for later drift comparison.',
    },
    {
      id: `p${pageNumber}-s4`,
      title: 'Record API responsiveness snapshot',
      description: 'Collect response metrics from healthz endpoints and API checks.',
      command: 'kubectl get --raw=/readyz?verbose',
      expected: 'Control-plane readiness checks succeed.',
      whyItMatters: 'Provides early signal if control plane is degraded.',
    },
    {
      id: `p${pageNumber}-s5`,
      title: 'Validate quota and limits coverage',
      description: 'Confirm namespace guardrails are in place before workload operations.',
      command: 'kubectl get resourcequota,limitrange -n lab-apps',
      expected: 'Quota and limit ranges are present and enforced.',
      whyItMatters: 'Reduces noisy failures from unbounded workloads.',
    },
    {
      id: `p${pageNumber}-s6`,
      title: 'Snapshot baseline events for module',
      description: `Collect recent events around ${focusArea} for module ${moduleNumber}.`,
      command: 'kubectl get events -A --sort-by=.lastTimestamp | tail -n 40',
      expected: 'Only expected warning patterns are present.',
      whyItMatters: 'Makes post-change anomaly detection easier.',
    },
    {
      id: `p${pageNumber}-s7`,
      title: 'Lock baseline in notes',
      description: 'Store command outputs and timestamps in the module notes area.',
      expected: 'Baseline evidence is captured with date/time and operator context.',
      whyItMatters: 'Supports fast rollback decisions and auditability.',
    },
  ];
}

function buildNetworkSteps(context: PageContext): WikiStep[] {
  const { moduleNumber, pageNumber, focusArea } = context;
  return [
    {
      id: `p${pageNumber}-s1`,
      title: 'Map service and ingress surface',
      description: 'Gather all relevant service ports and ingress targets for tests.',
      command: 'kubectl -n lab-apps get svc,ingress -o wide',
      expected: 'Service and ingress resources expose expected addresses/ports.',
      whyItMatters: 'Defines the exact interfaces that need validation.',
    },
    {
      id: `p${pageNumber}-s2`,
      title: 'Run in-cluster DNS resolution test',
      description: `Resolve Learning Hub service names from a transient pod focused on ${focusArea}.`,
      command:
        'kubectl run dns-check-m' +
        moduleNumber +
        ' --image=busybox:1.36 --restart=Never --rm -it -- nslookup learning-hub.lab-apps.svc.cluster.local',
      expected: 'Service FQDN resolves and returns cluster IP.',
      whyItMatters: 'Detects DNS misconfiguration before deeper traffic tests.',
    },
    {
      id: `p${pageNumber}-s3`,
      title: 'Validate endpoint backing pods',
      description: 'Ensure service endpoints are populated with ready pod addresses.',
      command: 'kubectl -n lab-apps get endpoints learning-hub -o yaml',
      expected: 'Endpoint subsets include active pod IPs.',
      whyItMatters: 'Prevents ingress black-hole conditions.',
    },
    {
      id: `p${pageNumber}-s4`,
      title: 'Probe ingress from external path',
      description: 'Call the public endpoint and verify route behavior.',
      command: 'curl -sS -D - http://<INGRESS_PUBLIC_IP>/ -o /dev/null',
      expected: 'HTTP response headers show healthy upstream behavior.',
      whyItMatters: 'Confirms internet-facing reachability.',
    },
    {
      id: `p${pageNumber}-s5`,
      title: 'Check cross-namespace egress behavior',
      description: 'Validate policies allow required DNS and service egress only.',
      command: 'kubectl get networkpolicy -A',
      expected: 'Allow rules for DNS and intended destinations are present.',
      whyItMatters: 'Catches policy regressions that silently break traffic.',
    },
    {
      id: `p${pageNumber}-s6`,
      title: 'Confirm latency baseline with repeated calls',
      description: 'Run multiple requests and observe latency consistency.',
      command: 'for i in $(seq 1 10); do curl -s -o /dev/null -w "%{http_code} %{time_total}\\n" http://<INGRESS_PUBLIC_IP>/; done',
      expected: 'Status and latency remain within expected range.',
      whyItMatters: 'Surface intermittent failures before production-like load.',
    },
    {
      id: `p${pageNumber}-s7`,
      title: 'Document network decision points',
      description: `Record findings, anomalies, and planned fixes for module ${moduleNumber}.`,
      expected: 'Clear notes include tested paths and observed outcomes.',
      whyItMatters: 'Enables reproducible troubleshooting in later modules.',
    },
  ];
}

function buildSecuritySteps(context: PageContext): WikiStep[] {
  const { moduleNumber, pageNumber, focusArea } = context;
  return [
    {
      id: `p${pageNumber}-s1`,
      title: 'Review namespace policy posture',
      description: 'Inspect all network and admission policies relevant to this page.',
      command: 'kubectl get networkpolicy -A',
      expected: 'Policy objects match expected baseline and naming.',
      whyItMatters: 'Policy drift is a leading source of hidden outages.',
    },
    {
      id: `p${pageNumber}-s2`,
      title: 'Inspect workload identity service account',
      description: `Validate annotations and token mount behavior for ${focusArea}.`,
      command: 'kubectl -n lab-apps get sa learning-hub-sa -o yaml',
      expected: 'Client-id annotation and identity settings are present.',
      whyItMatters: 'Identity issues often manifest as runtime dependency errors.',
    },
    {
      id: `p${pageNumber}-s3`,
      title: 'Validate RBAC with can-i checks',
      description: 'Test expected access paths for app service account.',
      command:
        'kubectl auth can-i get secrets -n lab-apps --as=system:serviceaccount:lab-apps:learning-hub-sa',
      expected: 'Permission result matches your intended least-privilege model.',
      whyItMatters: 'Prevents over-privileged or broken access configurations.',
    },
    {
      id: `p${pageNumber}-s4`,
      title: 'Check secret provider and mounted objects',
      description: 'Verify CSI secret sync and mounted values are healthy.',
      command: 'kubectl -n lab-apps get secretproviderclass,secret',
      expected: 'SecretProviderClass and synced Kubernetes secret exist.',
      whyItMatters: 'Protects apps from startup failures due to missing secrets.',
    },
    {
      id: `p${pageNumber}-s5`,
      title: 'Inspect pod security context and runtime hardening',
      description: 'Confirm non-root execution and capability drops are applied.',
      command: 'kubectl -n lab-apps describe pod -l app=learning-hub',
      expected: 'Security context shows non-root, no privilege escalation, dropped caps.',
      whyItMatters: 'Reduces lateral-movement risk and admission failures.',
    },
    {
      id: `p${pageNumber}-s6`,
      title: 'Review recent security-related events',
      description: `Search for denied operations linked to module ${moduleNumber}.`,
      command: 'kubectl get events -A --sort-by=.lastTimestamp | grep -Ei "denied|forbidden|policy"',
      expected: 'No unresolved high-severity denies affecting application flow.',
      whyItMatters: 'Turns silent policy breaks into actionable findings.',
    },
    {
      id: `p${pageNumber}-s7`,
      title: 'Capture security evidence pack',
      description: 'Store key command outputs and rationale for approvals/exceptions.',
      expected: 'Evidence includes identity, policy, and runtime posture checks.',
      whyItMatters: 'Supports formal sign-off for secure platform changes.',
    },
  ];
}

function buildWorkloadSteps(context: PageContext): WikiStep[] {
  const { moduleNumber, pageNumber, moduleTheme } = context;
  return [
    {
      id: `p${pageNumber}-s1`,
      title: 'Inspect deployment and HPA inventory',
      description: `Baseline workload state for ${moduleTheme}.`,
      command: 'kubectl -n lab-apps get deploy,pods,hpa -o wide',
      expected: 'Deployments and HPA resources align with desired counts.',
      whyItMatters: 'Confirms platform is in a known good state before rollout checks.',
    },
    {
      id: `p${pageNumber}-s2`,
      title: 'Validate rollout status and history',
      description: 'Ensure deployment revisions and rollout state are healthy.',
      command: 'kubectl -n lab-apps rollout status deployment/learning-hub && kubectl -n lab-apps rollout history deployment/learning-hub',
      expected: 'Rollout succeeds and revision history is consistent.',
      whyItMatters: 'Identifies stuck updates before traffic impact escalates.',
    },
    {
      id: `p${pageNumber}-s3`,
      title: 'Collect recent application logs',
      description: 'Review logs for startup, dependency, and runtime anomalies.',
      command: 'kubectl -n lab-apps logs deployment/learning-hub --tail=200',
      expected: 'No repeated fatal errors or probe failure loops.',
      whyItMatters: 'Logs expose latent issues not visible in deployment status.',
    },
    {
      id: `p${pageNumber}-s4`,
      title: 'Measure pod resource usage',
      description: 'Capture CPU and memory profile during active state.',
      command: 'kubectl -n lab-apps top pods',
      expected: 'Usage stays within requests/limits envelope.',
      whyItMatters: 'Protects against throttling and OOM during load.',
    },
    {
      id: `p${pageNumber}-s5`,
      title: 'Probe app and health endpoints',
      description: 'Validate user path and operational endpoint responses.',
      command: 'curl -sS -o /dev/null -w "%{http_code}\\n" http://<INGRESS_PUBLIC_IP>/ && curl -sS -o /dev/null -w "%{http_code}\\n" http://<INGRESS_PUBLIC_IP>/health',
      expected: 'Endpoints respond with expected status codes.',
      whyItMatters: 'Ensures app is externally accessible and operationally visible.',
    },
    {
      id: `p${pageNumber}-s6`,
      title: 'Simulate brief restart and observe recovery',
      description: 'Exercise a controlled restart to validate resilience.',
      command: 'kubectl -n lab-apps rollout restart deployment/learning-hub',
      expected: 'Pods recycle and return healthy within SLO window.',
      whyItMatters: 'Validates safe operations for maintenance and incident response.',
    },
    {
      id: `p${pageNumber}-s7`,
      title: 'Document reliability outcome',
      description: `Record whether module ${moduleNumber} workloads met reliability gates.`,
      expected: 'Decision is explicit: pass, conditional pass, or fail with actions.',
      whyItMatters: 'Improves release discipline across all modules.',
    },
  ];
}

function buildOperationsSteps(context: PageContext): WikiStep[] {
  const { moduleNumber, pageNumber, focusArea } = context;
  return [
    {
      id: `p${pageNumber}-s1`,
      title: 'Define incident drill scope',
      description: `Set expected blast radius and success criteria for ${focusArea}.`,
      expected: 'Scope, owner, and rollback criteria are clearly written.',
      whyItMatters: 'Prevents chaotic test execution during drills.',
    },
    {
      id: `p${pageNumber}-s2`,
      title: 'Trigger controlled failure mode',
      description: 'Introduce a safe failure stimulus (restart, scaling pressure, or dependency pause).',
      command: 'kubectl -n lab-apps rollout restart deployment/learning-hub',
      expected: 'Failure mode is observable and contained.',
      whyItMatters: 'Builds confidence in operational response under pressure.',
    },
    {
      id: `p${pageNumber}-s3`,
      title: 'Monitor live service impact',
      description: 'Track ingress response and pod status while drill runs.',
      command: 'kubectl -n lab-apps get pods -w',
      expected: 'Impact is measurable and within acceptable boundaries.',
      whyItMatters: 'Quantifies customer-facing effect of operational events.',
    },
    {
      id: `p${pageNumber}-s4`,
      title: 'Execute mitigation sequence',
      description: `Apply the documented recovery path for module ${moduleNumber}.`,
      command: 'kubectl -n lab-apps rollout status deployment/learning-hub',
      expected: 'Service returns to stable state.',
      whyItMatters: 'Proves your runbook is actionable, not theoretical.',
    },
    {
      id: `p${pageNumber}-s5`,
      title: 'Validate post-recovery signals',
      description: 'Confirm health, availability, and error budgets normalize.',
      command: 'kubectl -n lab-apps get deploy,pods,events --sort-by=.lastTimestamp',
      expected: 'No unresolved warning patterns remain.',
      whyItMatters: 'Ensures hidden degradation is caught before closure.',
    },
    {
      id: `p${pageNumber}-s6`,
      title: 'Capture timeline and root-cause hypothesis',
      description: 'Write timeline checkpoints and likely technical root cause.',
      expected: 'Timeline includes detection, mitigation, and recovery markers.',
      whyItMatters: 'Improves repeatability and learning over time.',
    },
    {
      id: `p${pageNumber}-s7`,
      title: 'Create follow-up actions',
      description: `Convert findings into improvements for future ${focusArea} operations.`,
      expected: 'Action items have owners and due windows.',
      whyItMatters: 'Turns drills into measurable platform maturity gains.',
    },
  ];
}

function buildSteps(context: PageContext): WikiStep[] {
  const { categoryKey } = context;
  if (categoryKey === 'foundation') return buildFoundationSteps(context);
  if (categoryKey === 'network') return buildNetworkSteps(context);
  if (categoryKey === 'security') return buildSecuritySteps(context);
  if (categoryKey === 'workloads') return buildWorkloadSteps(context);
  return buildOperationsSteps(context);
}

function buildPageSummary(pageNumber: number): WikiPageSummary {
  const context = createPageContext(pageNumber);
  const category = categories[context.categoryIndex];
  const difficulty = getDifficulty(context.moduleNumber, context.categoryIndex);
  const estimatedMinutes = getEstimatedMinutes(context.moduleNumber, context.categoryIndex);

  return {
    pageNumber,
    path: getPagePath(pageNumber),
    moduleNumber: context.moduleNumber,
    categoryKey: category.key,
    categoryShortLabel: category.shortLabel,
    categoryFullLabel: category.fullLabel,
    categoryAccent: category.accent,
    title: `Module ${context.moduleNumber}.${context.modulePageNumber}: ${category.fullLabel}`,
    summary: buildSummary(context),
    focusArea: context.focusArea,
    difficulty,
    estimatedMinutes,
  };
}

function buildPage(pageNumber: number): WikiPage {
  const summary = buildPageSummary(pageNumber);
  const context = createPageContext(pageNumber);

  return {
    ...summary,
    scenario: buildScenario(context),
    objective: buildObjective(context),
    prerequisites: buildPrerequisites(context),
    steps: buildSteps(context),
    verifications: buildVerifications(context),
    signalsToWatch: buildSignalsToWatch(context),
    commonFailures: buildFailurePatterns(context),
    notesPrompt: buildNotesPrompt(context),
    moduleTheme: context.moduleTheme,
    artSeed: pageNumber * 17 + context.moduleNumber * 11 + context.categoryIndex * 7,
  };
}

export function listWikiPages(): WikiPageSummary[] {
  return Array.from({ length: TOTAL_WIKI_PAGES }, (_, index) => buildPageSummary(index + 1));
}

export function listWikiModules(): WikiModuleSummary[] {
  return Array.from({ length: TOTAL_MODULES }, (_, moduleIndex) => {
    const moduleNumber = moduleIndex + 1;
    const startPage = moduleIndex * PAGES_PER_MODULE + 1;
    const moduleTheme = moduleThemes[(moduleNumber - 1) % moduleThemes.length];

    const pages = Array.from({ length: PAGES_PER_MODULE }, (_, pageOffset) =>
      buildPageSummary(startPage + pageOffset),
    );

    return {
      moduleNumber,
      moduleTheme,
      pages,
    };
  });
}

export function getWikiPage(pageNumber: number): WikiPage | null {
  if (!Number.isInteger(pageNumber) || pageNumber < 1 || pageNumber > TOTAL_WIKI_PAGES) {
    return null;
  }
  return buildPage(pageNumber);
}

export function getModulePages(moduleNumber: number): WikiPageSummary[] {
  if (!Number.isInteger(moduleNumber) || moduleNumber < 1 || moduleNumber > TOTAL_MODULES) {
    return [];
  }

  const startPage = (moduleNumber - 1) * PAGES_PER_MODULE + 1;
  return Array.from({ length: PAGES_PER_MODULE }, (_, index) => buildPageSummary(startPage + index));
}
