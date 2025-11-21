import { Feedback } from '@/lib/api';

interface FeedbackListProps {
  feedbacks: Feedback[];
}

/**
 * FeedbackList component
 * Displays a list of feedback items
 */
export default function FeedbackList({ feedbacks }: FeedbackListProps) {
  if (feedbacks.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-8 text-center">
        <p className="text-gray-500">No feedback available for this restaurant.</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {feedbacks.map((feedback) => (
        <div key={feedback.id} className="bg-white rounded-lg shadow p-6">
          <div className="flex justify-between items-start mb-3">
            <div className="flex-1">
              {feedback.user && (
                <div className="text-sm text-gray-600 mb-2">
                  <span className="font-medium">From:</span>{' '}
                  {feedback.user.name || feedback.user.email}
                  {feedback.user.name && (
                    <span className="text-gray-400"> ({feedback.user.email})</span>
                  )}
                </div>
              )}
            </div>
            <time className="text-sm text-gray-500">
              {new Date(feedback.createdAt).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
              })}
            </time>
          </div>
          
          <div className="text-gray-800 whitespace-pre-wrap">
            {feedback.message}
          </div>
        </div>
      ))}
    </div>
  );
}
