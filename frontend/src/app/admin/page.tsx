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
 * TODO: Update authentication logic based on the backend Auth0 implementation
 * - The backend should set session cookies after successful Auth0 login
 * - This page should check for valid session and redirect to login if needed
 * - You may need to adjust the auth checking mechanism based on backend implementation
 */
export default async function AdminPage() {
  // TODO: Implement proper authentication check
  // This is a placeholder - adjust based on backend Auth0 implementation
  // Options:
  // 1. Check for session cookie and validate it
  // 2. Call backend /api/auth/me endpoint to verify session
  // 3. Use middleware to handle auth before reaching this page
  
  let restaurants;
  let error: string | null = null;

  try {
    // For now, we'll attempt to fetch restaurants
    // In production, you should pass the session token from cookies
    // Example: const token = cookies().get('auth_token')?.value;
    
    // This will fail without proper authentication
    // You'll need to implement session management
    const token = ''; // TODO: Get from session/cookies
    
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
