import { getPosts } from '@/lib/sql';

export const dynamic = 'force-dynamic';

export default async function BlogPage() {
  const posts = await getPosts();

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Blog</h1>
      <p className="text-gray-600 dark:text-gray-400 mb-8">
        Articles about AKS, cloud-native patterns, and infrastructure as code.
        <span className="text-xs ml-2 bg-azure-500/10 text-azure-500 px-2 py-1 rounded">Stored in Azure SQL</span>
      </p>

      <div className="space-y-6">
        {posts.map((post) => (
          <article
            key={post.id}
            className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6 border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow"
          >
            <div className="flex items-center space-x-3 mb-3">
              <span className="text-xs font-medium bg-azure-500/10 text-azure-500 px-2.5 py-1 rounded-full">
                {post.category}
              </span>
              <span className="text-xs text-gray-500 dark:text-gray-400">
                {new Date(post.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}
              </span>
            </div>
            <a href={`/blog/${post.slug}`}>
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white hover:text-azure-500 transition-colors mb-2">
                {post.title}
              </h2>
            </a>
            <p className="text-gray-600 dark:text-gray-300 line-clamp-2">
              {post.content}
            </p>
            <a
              href={`/blog/${post.slug}`}
              className="inline-block mt-3 text-azure-500 hover:text-azure-600 text-sm font-medium"
            >
              Read more →
            </a>
          </article>
        ))}
      </div>
    </div>
  );
}
