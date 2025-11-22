import { notFound, redirect } from 'next/navigation';
import Link from 'next/link';
import AdminLayout from '@/components/admin/AdminLayout';
import FeedbackList from '@/components/admin/FeedbackList';
import apiClient from '@/lib/api';

interface PageProps {
  params: Promise<{
    id: string;
  }>;
}

/**
 * Restaurant Detail Page
 * 
 * Displays detailed information about a specific restaurant
 * and lists all feedback associated with it.
 * 
 * ⚠️ SECURITY WARNING: Authentication is not fully implemented!
 * The current implementation uses an empty token which allows unauthorized access.
 * This is a PLACEHOLDER and MUST be updated before production deployment.
 * 
 * TODO: Update authentication logic to match backend Auth0 implementation
 * Implementation steps:
 * 1. Import Next.js cookies() from 'next/headers'
 * 2. Retrieve the auth token/session from cookies
 * 3. Validate the token with the backend
 * 4. Redirect to login if invalid or missing
 */
export default async function RestaurantDetailPage({ params }: PageProps) {
  const { id } = await params;
  const restaurantId = parseInt(id, 10);

  if (isNaN(restaurantId)) {
    notFound();
  }

  // ⚠️ SECURITY: Token is empty - this allows unauthorized access!
  // TODO: Implement proper authentication check
  // Example: const token = cookies().get('auth_token')?.value || '';
  const token = ''; // TODO: Get from session/cookies - DO NOT DEPLOY WITHOUT FIXING THIS
  
  if (!token) {
    redirect(`${process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000'}/api/auth/login`);
  }

  let restaurant;
  let feedbacks;
  let error: string | null = null;

  try {
    // Fetch restaurant and feedbacks in parallel
    [restaurant, feedbacks] = await Promise.all([
      apiClient.getRestaurant(restaurantId, token),
      apiClient.getRestaurantFeedbacks(restaurantId, token).catch(() => []),
    ]);
  } catch (err) {
    console.error('Failed to fetch restaurant:', err);
    error = err instanceof Error ? err.message : 'Failed to load restaurant';
  }

  if (error || !restaurant) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <Link
            href="/admin"
            className="inline-flex items-center text-blue-600 hover:text-blue-800"
          >
            ← Back to Dashboard
          </Link>

          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-red-800">
              <strong>Error:</strong> {error || 'Restaurant not found'}
            </p>
          </div>
        </div>
      </AdminLayout>
    );
  }

  return (
    <AdminLayout>
      <div className="space-y-8">
        {/* Back button */}
        <Link
          href="/admin"
          className="inline-flex items-center text-blue-600 hover:text-blue-800"
        >
          ← Back to Dashboard
        </Link>

        {/* Restaurant Details */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="border-b pb-4 mb-4">
            <h2 className="text-3xl font-bold text-gray-900">
              {restaurant.name}
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-3">
              <h3 className="text-lg font-semibold text-gray-900">
                Contact Information
              </h3>
              
              {restaurant.address && (
                <div>
                  <label className="text-sm font-medium text-gray-500">Address</label>
                  <p className="text-gray-900">{restaurant.address}</p>
                </div>
              )}

              {restaurant.phone && (
                <div>
                  <label className="text-sm font-medium text-gray-500">Phone</label>
                  <p className="text-gray-900">{restaurant.phone}</p>
                </div>
              )}

              {restaurant.email && (
                <div>
                  <label className="text-sm font-medium text-gray-500">Email</label>
                  <p className="text-gray-900">{restaurant.email}</p>
                </div>
              )}
            </div>

            <div className="space-y-3">
              <h3 className="text-lg font-semibold text-gray-900">
                Online Presence
              </h3>

              {restaurant.website && (
                <div>
                  <label className="text-sm font-medium text-gray-500">Website</label>
                  <a
                    href={restaurant.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:text-blue-800 block"
                  >
                    {restaurant.website}
                  </a>
                </div>
              )}

              {restaurant.instagram && (
                <div>
                  <label className="text-sm font-medium text-gray-500">Instagram</label>
                  <a
                    href={`https://instagram.com/${restaurant.instagram.replace('@', '')}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-pink-600 hover:text-pink-800 block"
                  >
                    @{restaurant.instagram.replace('@', '')}
                  </a>
                </div>
              )}
            </div>
          </div>

          {restaurant.description && (
            <div className="mt-6 pt-6 border-t">
              <label className="text-sm font-medium text-gray-500 block mb-2">
                Description
              </label>
              <p className="text-gray-900 whitespace-pre-wrap">
                {restaurant.description}
              </p>
            </div>
          )}

          {/* Restaurant metadata */}
          <div className="mt-6 pt-6 border-t text-sm text-gray-500">
            <p>
              <strong>ID:</strong> {restaurant.id}
            </p>
            {restaurant.created_at && (
              <p>
                <strong>Created:</strong>{' '}
                {new Date(restaurant.created_at).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </p>
            )}
          </div>
        </div>

        {/* Feedback Section */}
        <div>
          <h2 className="text-2xl font-bold text-gray-900 mb-4">
            Customer Feedback
          </h2>
          <FeedbackList feedbacks={feedbacks || []} />
        </div>
      </div>
    </AdminLayout>
  );
}
