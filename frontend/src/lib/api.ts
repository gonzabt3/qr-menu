/**
 * API Client for communicating with the Rails backend
 * 
 * This client uses the NEXT_PUBLIC_BACKEND_URL environment variable
 * to determine the backend API endpoint.
 */

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000';

interface FetchOptions extends RequestInit {
  token?: string;
}

/**
 * Generic fetch wrapper with error handling
 */
async function apiFetch<T>(endpoint: string, options: FetchOptions = {}): Promise<T> {
  const { token, ...fetchOptions } = options;
  
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(fetchOptions.headers as Record<string, string>),
  };

  // Add Authorization header if token is provided
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const url = `${BACKEND_URL}${endpoint}`;
  
  try {
    const response = await fetch(url, {
      ...fetchOptions,
      headers,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: response.statusText }));
      throw new Error(error.message || `API Error: ${response.status}`);
    }

    // Handle empty responses
    const contentType = response.headers.get('content-type');
    if (!contentType?.includes('application/json')) {
      return {} as T;
    }

    return await response.json();
  } catch (error) {
    console.error('API fetch error:', error);
    throw error;
  }
}

/**
 * Restaurant type definition
 */
export interface Restaurant {
  id: number;
  name: string;
  address?: string;
  phone?: string;
  email?: string;
  website?: string;
  instagram?: string;
  description?: string;
  created_at?: string;
  updated_at?: string;
}

/**
 * Feedback type definition
 */
export interface Feedback {
  id: number;
  message: string;
  user?: {
    id: number;
    email: string;
    name?: string;
  } | null;
  createdAt: string;
}

/**
 * User/Auth type definition
 */
export interface User {
  id: number;
  email: string;
  name?: string;
  auth0_id?: string;
}

/**
 * API Client methods
 */
export const apiClient = {
  /**
   * Check authentication status
   * TODO: Update this endpoint based on the backend implementation
   * The backend should provide an endpoint to verify current user session
   */
  async checkAuth(token?: string): Promise<User | null> {
    try {
      // This endpoint needs to be implemented in the backend
      // For now, we'll use a placeholder
      const user = await apiFetch<User>('/api/auth/me', { token });
      return user;
    } catch (error) {
      console.error('Auth check failed:', error);
      return null;
    }
  },

  /**
   * Get all restaurants
   */
  async getRestaurants(token: string): Promise<Restaurant[]> {
    return apiFetch<Restaurant[]>('/restaurants', { token });
  },

  /**
   * Get a single restaurant by ID
   */
  async getRestaurant(id: number, token: string): Promise<Restaurant> {
    return apiFetch<Restaurant>(`/restaurants/${id}`, { token });
  },

  /**
   * Get all feedbacks
   * Note: This endpoint uses a different authentication method (secret header)
   * TODO: Adapt this based on admin authentication requirements
   */
  async getFeedbacks(secret?: string): Promise<Feedback[]> {
    const headers: Record<string, string> = {};
    if (secret) {
      headers['X-Feedback-Secret'] = secret;
    }
    return apiFetch<Feedback[]>('/feedbacks', { headers });
  },

  /**
   * Get feedbacks for a specific restaurant
   * TODO: This endpoint may need to be implemented in the backend
   * For now, we'll fetch all feedbacks and filter client-side
   */
  async getRestaurantFeedbacks(restaurantId: number, token: string): Promise<Feedback[]> {
    // This is a placeholder - the backend may need a specific endpoint
    // for restaurant-specific feedback
    try {
      const allFeedbacks = await apiFetch<Feedback[]>('/feedbacks', { token });
      // TODO: Filter by restaurant ID when backend provides restaurant association
      // For now, return all feedbacks (backend doesn't associate feedback with restaurants yet)
      return allFeedbacks;
    } catch (error) {
      console.error('Failed to fetch feedbacks:', error);
      return [];
    }
  },

  /**
   * Login URL - redirects to backend auth endpoint
   * TODO: Update based on the backend Auth0 implementation
   */
  getLoginUrl(): string {
    return `${BACKEND_URL}/api/auth/login`;
  },

  /**
   * Logout URL - redirects to backend logout endpoint
   * TODO: Update based on the backend Auth0 implementation
   */
  getLogoutUrl(): string {
    return `${BACKEND_URL}/api/auth/logout`;
  },
};

export default apiClient;
