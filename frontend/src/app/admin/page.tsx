import { redirect } from 'next/navigation';
import AdminLayout from '@/components/admin/AdminLayout';
import RestaurantList from '@/components/admin/RestaurantList';
import apiClient from '@/lib/api';

/**
 * Admin Dashboard Page
 * 
 * This page displays a list of all restaurants.
 * It requires authentication via the backend Auth0 implementation.
 * 
 * ⚠️ SECURITY WARNING: Authentication is not fully implemented!
 * The current implementation uses an empty token which allows unauthorized access.
 * This is a PLACEHOLDER and MUST be updated before production deployment.
 * 
 * TODO: Update authentication logic based on the backend Auth0 implementation
 * - The backend should set session cookies after successful Auth0 login
 * - This page should check for valid session and redirect to login if needed
 * - You may need to adjust the auth checking mechanism based on backend implementation
 * 
 * Implementation steps:
 * 1. Import Next.js cookies() from 'next/headers'
 * 2. Retrieve the auth token/session from cookies
 * 3. Validate the token with the backend
 * 4. Redirect to login if invalid or missing
 */
export default async function AdminPage() {
  // ⚠️ SECURITY: Token is empty - this allows unauthorized access!
  // TODO: Implement proper authentication check
  // Example: const token = cookies().get('auth_token')?.value || '';
  
  let restaurants;
  let error: string | null = null;

  try {
    // ⚠️ SECURITY WARNING: Empty token bypasses authentication
    const token = ''; // TODO: Get from session/cookies - DO NOT DEPLOY WITHOUT FIXING THIS
    
    if (!token) {
      // Redirect to backend login if no token
      redirect(`${process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000'}/api/auth/login`);
    }
    
    restaurants = await apiClient.getRestaurants(token);
  } catch (err) {
    console.error('Failed to fetch restaurants:', err);
    error = err instanceof Error ? err.message : 'Failed to load restaurants';
    // If authentication fails, redirect to login
    // redirect(`${process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000'}/api/auth/login`);
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">Restaurants</h2>
            <p className="text-gray-600 mt-1">
              Manage and view all restaurants in the system
            </p>
          </div>
        </div>

        {error ? (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-red-800">
              <strong>Error:</strong> {error}
            </p>
            <p className="text-red-600 text-sm mt-2">
              Please ensure you are authenticated and the backend API is running.
            </p>
            <a
              href={`${process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000'}/api/auth/login`}
              className="inline-block mt-4 bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
            >
              Login
            </a>
          </div>
        ) : restaurants && restaurants.length > 0 ? (
          <RestaurantList restaurants={restaurants} />
        ) : (
          <div className="bg-white rounded-lg shadow p-12 text-center">
            <p className="text-gray-500 text-lg">No restaurants found.</p>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
