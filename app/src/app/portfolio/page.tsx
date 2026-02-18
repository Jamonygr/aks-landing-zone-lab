import { getProjects } from '@/lib/sql';

export const dynamic = 'force-dynamic';

export default async function PortfolioPage() {
  const projects = await getProjects();

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Portfolio</h1>
      <p className="text-gray-600 dark:text-gray-400 mb-8">
        AKS projects, certifications, and infrastructure built during the lab.
        <span className="text-xs ml-2 bg-azure-500/10 text-azure-500 px-2 py-1 rounded">Stored in Azure SQL</span>
      </p>

      <div className="grid md:grid-cols-2 gap-6">
        {projects.map((project) => (
          <div
            key={project.id}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6 border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow"
          >
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              {project.title}
            </h2>
            <p className="text-gray-600 dark:text-gray-300 text-sm mb-4">
              {project.description}
            </p>
            <div className="flex flex-wrap gap-1.5 mb-4">
              {project.tech_stack.split(', ').map((tech) => (
                <span
                  key={tech}
                  className="text-xs bg-azure-500/10 text-azure-500 px-2 py-0.5 rounded"
                >
                  {tech}
                </span>
              ))}
            </div>
            {project.url && project.url !== '#' && (
              <a
                href={project.url}
                className="text-azure-500 hover:text-azure-600 text-sm font-medium"
                target="_blank"
                rel="noopener noreferrer"
              >
                View project →
              </a>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
