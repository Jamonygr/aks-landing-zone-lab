const pillars = [
  {
    title: 'Cluster Fundamentals',
    summary: 'Understand control plane, node pools, scheduling, probes, and zero-downtime rollout strategy.',
  },
  {
    title: 'Networking and Security',
    summary: 'Design hub-spoke connectivity, network policies, private endpoints, and secrets delivery patterns.',
  },
  {
    title: 'Observability and Scaling',
    summary: 'Build dashboards, alerting, metrics pipelines, and autoscaling behavior for production workloads.',
  },
];

const phases = [
  {
    phase: 'Phase 01',
    name: 'Bootstrap',
    items: ['AKS architecture map', 'IaC deployment flow', 'Container image lifecycle'],
  },
  {
    phase: 'Phase 02',
    name: 'Operate',
    items: ['Ingress and routing', 'Workload Identity auth', 'SQL over private endpoint'],
  },
  {
    phase: 'Phase 03',
    name: 'Harden',
    items: ['Policy enforcement', 'Alert tuning', 'Cost and reliability guardrails'],
  },
];

const stack = [
  'Kubernetes',
  'Azure Kubernetes Service',
  'Terraform',
  'Helm',
  'NGINX Ingress',
  'Azure Container Registry',
  'Azure SQL',
  'Key Vault + CSI',
  'Log Analytics',
  'Prometheus + Grafana',
];

export default function Home() {
  return (
    <div className="mx-auto max-w-7xl px-4 pb-16 sm:px-6 lg:px-8">
      <section className="grid gap-8 pb-14 pt-16 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
        <div className="fade-in-up">
          <p className="mono-label mb-4 inline-flex rounded-full border border-sky-200 bg-sky-50 px-3 py-1 text-xs font-medium uppercase tracking-[0.14em] text-sky-800">
            Learning Kubernetes
          </p>
          <h1 className="max-w-3xl text-4xl font-semibold leading-tight tracking-tight text-slate-900 sm:text-5xl lg:text-6xl">
            Build Kubernetes confidence with a real production-style AKS platform.
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-slate-600">
            This homepage is your entry point to modern Kubernetes engineering. You learn by running a complete platform:
            networking, security, observability, and app delivery, not toy examples.
          </p>
          <div className="mt-8 flex flex-wrap items-center gap-3">
            <a
              href="#curriculum"
              className="rounded-xl bg-sky-700 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-sky-800"
            >
              Start Curriculum
            </a>
            <a
              href="#stack"
              className="rounded-xl border border-slate-300 bg-white px-5 py-3 text-sm font-semibold text-slate-800 transition hover:border-slate-400 hover:bg-slate-50"
            >
              Explore Stack
            </a>
          </div>
        </div>

        <div className="fade-in-up-delayed float-slow panel rounded-3xl p-6 shadow-xl shadow-slate-200/60 sm:p-7">
          <p className="mono-label text-xs font-medium uppercase tracking-[0.16em] text-slate-500">Platform Snapshot</p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Kubernetes</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">v1.32</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Runtime</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">AKS</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Network</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">Hub-Spoke</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white p-4">
              <p className="mono-label text-[11px] uppercase tracking-[0.12em] text-slate-500">Data Plane</p>
              <p className="mt-1 text-xl font-semibold text-slate-900">SQL + Private Link</p>
            </div>
          </div>
          <div className="mt-4 rounded-xl border border-teal-200 bg-teal-50 p-4 text-sm text-teal-900">
            You are learning the same workflow used by platform teams: provision, verify, observe, and iterate.
          </div>
        </div>
      </section>

      <section className="grid gap-4 md:grid-cols-3">
        {pillars.map((pillar) => (
          <article key={pillar.title} className="panel rounded-2xl p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-900">{pillar.title}</h2>
            <p className="mt-3 text-sm leading-relaxed text-slate-600">{pillar.summary}</p>
          </article>
        ))}
      </section>

      <section id="curriculum" className="pt-16">
        <div className="mb-6 flex items-end justify-between gap-4">
          <h3 className="section-title font-semibold text-slate-900">Three-Phase Learning Path</h3>
          <span className="mono-label text-xs uppercase tracking-[0.14em] text-slate-500">Hands-on by design</span>
        </div>
        <div className="grid gap-4 lg:grid-cols-3">
          {phases.map((phase) => (
            <article key={phase.phase} className="panel rounded-2xl p-6 shadow-sm">
              <p className="mono-label text-xs uppercase tracking-[0.14em] text-sky-800">{phase.phase}</p>
              <h4 className="mt-2 text-xl font-semibold text-slate-900">{phase.name}</h4>
              <ul className="mt-4 space-y-2 text-sm text-slate-600">
                {phase.items.map((item) => (
                  <li key={item} className="rounded-md bg-white/80 px-3 py-2">{item}</li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      </section>

      <section id="stack" className="pt-16">
        <h3 className="section-title font-semibold text-slate-900">Platform Stack You Will Touch</h3>
        <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
          {stack.map((tool) => (
            <div
              key={tool}
              className="rounded-xl border border-slate-200 bg-white px-3 py-3 text-center text-sm font-medium text-slate-700 shadow-sm"
            >
              {tool}
            </div>
          ))}
        </div>
      </section>

      <section id="start" className="pt-16">
        <div className="panel rounded-3xl border-sky-200 bg-gradient-to-r from-sky-50 via-white to-amber-50 p-8 shadow-lg">
          <p className="mono-label text-xs uppercase tracking-[0.14em] text-sky-800">Ready to Start</p>
          <h3 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900">
            Turn Kubernetes concepts into repeatable platform skills.
          </h3>
          <p className="mt-3 max-w-2xl text-slate-600">
            Deploy the stack, run the workloads, inspect telemetry, and learn the operational decisions that matter in
            production.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <a
              href="/labs"
              className="rounded-xl bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800"
            >
              Open Labs
            </a>
            <a
              href="/blog"
              className="rounded-xl border border-slate-300 bg-white px-5 py-3 text-sm font-semibold text-slate-800 transition hover:bg-slate-50"
            >
              Read Learning Notes
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
