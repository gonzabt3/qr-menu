import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

/**
 * Middleware for protecting admin routes
 * 
 * This middleware intercepts requests to /admin routes and checks authentication.
 * 
 * ⚠️ SECURITY WARNING: Authentication is not implemented!
 * The current implementation allows ALL requests to admin routes without checking credentials.
 * This is a PLACEHOLDER and MUST be updated before production deployment.
 * 
 * TODO: Implement proper authentication checks based on your backend implementation.
 * Options include:
 * 1. Check for session cookie from backend Auth0 flow
 * 2. Validate JWT token in cookies
 * 3. Make a request to backend /api/auth/me to verify session
 * 
 * Implementation example:
 * ```typescript
 * const sessionCookie = request.cookies.get('session_token');
 * if (!sessionCookie) {
 *   const loginUrl = new URL(
 *     `${process.env.NEXT_PUBLIC_BACKEND_URL}/api/auth/login`,
 *     request.url
 *   );
 *   return NextResponse.redirect(loginUrl);
 * }
 * // Optionally verify the session with the backend
 * const isValid = await verifySessionWithBackend(sessionCookie.value);
 * if (!isValid) {
 *   return NextResponse.redirect(loginUrl);
 * }
 * ```
 */
export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Only protect /admin routes
  if (!pathname.startsWith('/admin')) {
    return NextResponse.next();
  }

  // ⚠️ SECURITY WARNING: No authentication check implemented!
  // This currently allows unauthorized access to all admin routes.
  // DO NOT DEPLOY TO PRODUCTION WITHOUT IMPLEMENTING AUTHENTICATION.
  
  console.warn('⚠️  Admin middleware authentication not implemented - allowing all requests');
  console.warn('⚠️  This is a security vulnerability - implement authentication before production');
  
  return NextResponse.next();
}

/**
 * Configure which routes this middleware applies to
 */
export const config = {
  matcher: '/admin/:path*',
};
