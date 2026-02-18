import { getPostBySlug } from '@/lib/sql';
import { getComments } from '@/lib/sql';
import { notFound } from 'next/navigation';

export const dynamic = 'force-dynamic';

export default async function BlogPostPage({ params }: { params: { slug: string } }) {
  const post = await getPostBySlug(params.slug);
  if (!post) return notFound();

  const comments = await getComments(post.id.toString());

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <a href="/blog" className="text-azure-500 hover:text-azure-600 text-sm mb-6 inline-block">
        ← Back to Blog
      </a>

      <article className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-8 border border-gray-200 dark:border-gray-700">
        <div className="flex items-center space-x-3 mb-4">
          <span className="text-xs font-medium bg-azure-500/10 text-azure-500 px-2.5 py-1 rounded-full">
            {post.category}
          </span>
          <span className="text-xs text-gray-500 dark:text-gray-400">
            {new Date(post.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}
          </span>
        </div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-6">{post.title}</h1>
        <div className="prose dark:prose-invert max-w-none text-gray-700 dark:text-gray-300 leading-relaxed">
          <p>{post.content}</p>
        </div>
      </article>

      {/* Comments section */}
      <div className="mt-8 bg-white dark:bg-gray-800 rounded-xl shadow-md p-8 border border-gray-200 dark:border-gray-700">
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          Comments
          <span className="text-xs ml-2 bg-green-500/10 text-green-500 px-2 py-1 rounded">Stored in SQL</span>
        </h2>
        {comments.length === 0 ? (
          <p className="text-gray-500 dark:text-gray-400 text-sm">No comments yet. Be the first to comment!</p>
        ) : (
          <div className="space-y-4">
            {comments.map((comment) => (
              <div key={comment.id} className="border-l-2 border-azure-500 pl-4 py-2">
                <div className="flex items-center space-x-2 mb-1">
                  <span className="font-medium text-gray-900 dark:text-white text-sm">{comment.author}</span>
                  <span className="text-xs text-gray-500 dark:text-gray-400">
                    {new Date(comment.timestamp).toLocaleString()}
                  </span>
                </div>
                <p className="text-gray-600 dark:text-gray-300 text-sm">{comment.content}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
