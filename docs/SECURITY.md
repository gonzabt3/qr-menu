# Security Considerations for Admin Backoffice

## ⚠️ IMPORTANT: Authentication Not Fully Implemented

The admin backoffice frontend includes **placeholder authentication** that currently allows unauthorized access to admin routes. This is intentional for development purposes but **MUST be updated before production deployment**.

## Current State

### What's Implemented (Placeholders)

1. **Middleware Protection** (`frontend/src/middleware.ts`)
   - Route protection structure exists
   - Currently allows all requests with console warnings
   - Includes example code and TODOs for implementation

2. **Page-Level Auth Guards** 
   - Admin pages check for tokens
   - Empty token handling with redirects
   - Clear security warnings in comments

3. **API Client** (`frontend/src/lib/api.ts`)
   - Auth token handling structure
   - Login/logout URL helpers
   - Backend integration points documented

### What Needs Implementation

Before deploying to production, you MUST implement:

1. **Session/Token Retrieval**
   - Retrieve auth tokens from cookies after backend Auth0 login
   - Example: `cookies().get('auth_token')?.value`

2. **Token Validation**
   - Verify tokens with the backend
   - Handle token expiration
   - Implement token refresh if needed

3. **Middleware Authentication**
   - Check for valid session cookies
   - Redirect unauthorized users to login
   - Optional: Verify session with backend

4. **Backend Endpoints**
   - Implement `/api/auth/me` endpoint in backend for session verification
   - Configure `/api/auth/login` Auth0 redirect
   - Configure `/api/auth/logout` session cleanup

## Security Best Practices

### For Implementation

1. **Use HTTP-only Cookies**
   ```typescript
   // Backend should set cookies with these flags
   response.set_cookie('auth_token', token, {
     httponly: true,
     secure: true,
     samesite: 'lax'
   })
   ```

2. **Server-Side Token Validation**
   ```typescript
   // In middleware or page components
   const token = cookies().get('auth_token')?.value;
   if (!token) {
     redirect(loginUrl);
   }
   
   // Verify with backend
   const user = await verifyToken(token);
   if (!user) {
     redirect(loginUrl);
   }
   ```

3. **CORS Configuration**
   - Configure Rails backend to allow requests from frontend domain
   - Set appropriate CORS headers for credentials

4. **Environment Variables**
   - Never commit `.env.local` files
   - Use different secrets for dev/staging/production
   - Rotate secrets regularly

### Authentication Flow

Recommended flow for integrating with backend Auth0:

```
1. User visits /admin (frontend)
   ↓
2. Middleware checks for auth cookie
   ↓ (no cookie)
3. Redirect to backend /api/auth/login
   ↓
4. Backend redirects to Auth0
   ↓
5. User authenticates with Auth0
   ↓
6. Auth0 redirects to backend callback
   ↓
7. Backend validates Auth0 token
   ↓
8. Backend creates session cookie
   ↓
9. Backend redirects to frontend /admin
   ↓
10. Middleware allows access (cookie present)
```

## Testing Authentication

### Local Development

1. **Start Backend with Auth0**
   ```bash
   # Configure Auth0 environment variables
   export AUTH0_DOMAIN=your-domain.auth0.com
   export AUTH0_CLIENT_ID=your-client-id
   export AUTH0_CLIENT_SECRET=your-secret
   
   # Start Rails
   rails server
   ```

2. **Start Frontend**
   ```bash
   cd frontend
   export NEXT_PUBLIC_BACKEND_URL=http://localhost:3000
   npm run dev
   ```

3. **Test Flow**
   - Visit http://localhost:3001/admin
   - Should redirect to backend login
   - After Auth0 login, should redirect back
   - Admin pages should be accessible

### Production Checklist

Before deploying to production:

- [ ] Authentication fully implemented in middleware
- [ ] Page-level auth guards updated with real token retrieval
- [ ] Backend Auth0 endpoints configured and tested
- [ ] Session cookies properly secured (httponly, secure, samesite)
- [ ] CORS configured correctly
- [ ] All TODO comments addressed
- [ ] Security warnings removed from logs
- [ ] Auth flow tested end-to-end
- [ ] Token expiration handling implemented
- [ ] Logout properly clears sessions

## Reporting Security Issues

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do not** create a public GitHub issue
2. Contact the repository maintainers directly through GitHub's private vulnerability reporting feature
3. Or email the repository owner listed in the GitHub profile

Include in your report:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Additional Resources

- [Auth0 Documentation](https://auth0.com/docs)
- [Next.js Authentication Patterns](https://nextjs.org/docs/authentication)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
