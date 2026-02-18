import { getExercises } from '@/lib/sql';

export const dynamic = 'force-dynamic';

export default async function LabsPage() {
  const exercises = await getExercises();
  const completedCount = exercises.filter((e) => e.completed).length;
  const progressPct = exercises.length > 0 ? Math.round((completedCount / exercises.length) * 100) : 0;

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Lab Exercises</h1>
      <p className="text-gray-600 dark:text-gray-400 mb-6">
        Track your progress through AKS landing zone concepts.
        <span className="text-xs ml-2 bg-azure-500/10 text-azure-500 px-2 py-1 rounded">Progress in Azure SQL</span>
        <span className="text-xs ml-1 bg-green-500/10 text-green-500 px-2 py-1 rounded">Activity in SQL</span>
      </p>

      {/* Progress bar */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6 border border-gray-200 dark:border-gray-700 mb-8">
        <div className="flex justify-between items-center mb-2">
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Overall Progress</span>
          <span className="text-sm font-bold text-azure-500">{completedCount}/{exercises.length} ({progressPct}%)</span>
        </div>
        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
          <div
            className="bg-azure-500 h-3 rounded-full transition-all duration-500"
            style={{ width: `${progressPct}%` }}
          ></div>
        </div>
      </div>

      {/* Exercise list */}
      <div className="space-y-4">
        {exercises.map((exercise) => (
          <div
            key={exercise.id}
            className={`bg-white dark:bg-gray-800 rounded-xl shadow-sm p-5 border ${
              exercise.completed
                ? 'border-green-300 dark:border-green-700'
                : 'border-gray-200 dark:border-gray-700'
            } hover:shadow-md transition-shadow`}
          >
            <div className="flex items-start justify-between">
              <div className="flex items-start space-x-3">
                <span className={`mt-0.5 text-lg ${exercise.completed ? '✅' : '⬜'}`}>
                  {exercise.completed ? '✅' : '⬜'}
                </span>
                <div>
                  <h3 className={`font-semibold ${
                    exercise.completed
                      ? 'text-green-700 dark:text-green-400 line-through'
                      : 'text-gray-900 dark:text-white'
                  }`}>
                    {exercise.title}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300 text-sm mt-1">{exercise.description}</p>
                </div>
              </div>
              <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${
                exercise.difficulty === 'Beginner' ? 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300' :
                exercise.difficulty === 'Intermediate' ? 'bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300' :
                'bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300'
              }`}>
                {exercise.difficulty}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
