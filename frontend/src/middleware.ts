import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

/**
 * Middleware for protecting admin routes
 * 
 * This middleware intercepts requests to /admin routes and checks authentication.
 * 
 * TODO: Implement proper authentication checks based on your backend implementation.
 * Options include:
 * 1. Check for session cookie from backend Auth0 flow
 * 2. Validate JWT token in cookies
 * 3. Make a request to backend /api/auth/me to verify session
 * 
 * Current implementation is a placeholder that always allows access.
 * You MUST update this before deploying to production.
 */
export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Only protect /admin routes
  if (!pathname.startsWith('/admin')) {
    return NextResponse.next();
  }

  // TODO: Implement authentication check
  // Example approaches:
  
  // Option 1: Check for session cookie
  // const sessionCookie = request.cookies.get('session_token');
  // if (!sessionCookie) {
  //   const loginUrl = new URL(`${process.env.NEXT_PUBLIC_BACKEND_URL}/api/auth/login`, request.url);
  //   return NextResponse.redirect(loginUrl);
  // }

  // Option 2: Validate JWT token
  // const token = request.cookies.get('auth_token');
  // if (!token || !isValidToken(token.value)) {
  //   return NextResponse.redirect(new URL('/login', request.url));
  // }

  // Option 3: Forward request to backend for verification
  // This approach is more complex but most secure
  // Make a request to your backend to verify the session
  // If backend returns 401, redirect to login

  // PLACEHOLDER: Currently allows all requests
  // Remove or replace this before production deployment
  console.warn('⚠️  Admin middleware authentication not implemented - allowing all requests');
  
  return NextResponse.next();
}

/**
 * Configure which routes this middleware applies to
 */
export const config = {
  matcher: '/admin/:path*',
};
