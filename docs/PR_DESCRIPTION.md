# Admin Backoffice Implementation - Pull Request

## Overview

This PR adds a Next.js frontend admin backoffice to the qr-menu repository. The admin interface provides a read-only view of restaurants and customer feedback, designed to integrate with the Rails backend's Auth0 authentication system.

## Features Added

### 1. Admin Dashboard (`/admin`)
- **Restaurant Listing**: Displays all restaurants in a paginated grid
- **Search Functionality**: Filter restaurants by name, address, or description
- **Pagination**: 10 items per page with navigation controls
- **Responsive Design**: Mobile-friendly layout using Tailwind CSS

### 2. Restaurant Detail Page (`/admin/restaurants/[id]`)
- **Restaurant Information**: Name, address, contact details, social media links
- **Feedback Viewing**: List of all customer feedback for the restaurant
- **User Information**: Shows feedback author when available
- **Timestamps**: Formatted creation dates

### 3. Admin Components
- **AdminLayout**: Consistent header with navigation and logout button
- **RestaurantList**: Searchable, paginated restaurant grid (client component)
- **RestaurantCard**: Individual restaurant display with key info
- **FeedbackList**: Customer feedback display with user details

### 4. API Integration
- **API Client** (`src/lib/api.ts`): Type-safe backend communication
- **Environment Configuration**: Configurable backend URL
- **Error Handling**: Graceful error states with user feedback
- **Type Definitions**: TypeScript interfaces for Restaurant, Feedback, User

### 5. Documentation
- **Admin Guide** (`docs/Admin.md`): Complete setup and usage instructions
- **Security Documentation** (`docs/SECURITY.md`): Security considerations and implementation guide
- **README Updates**: Quick start guide for admin interface

## Technical Stack

- **Next.js 15** with App Router
- **TypeScript** for type safety
- **Tailwind CSS** for styling
- **Server Components** for better performance
- **Client Components** for interactive features (search, pagination)

## Architecture Decisions

### Why Next.js App Router?
- Server-side rendering for better security and performance
- Built-in routing with file-based structure
- Easy integration with backend APIs
- Modern React features (Server Components)

### Why Separate Frontend?
- Clear separation of concerns
- Independent deployment options
- Different scaling requirements
- Better developer experience with hot reload

### Component Structure
```
frontend/
├── src/
│   ├── app/
│   │   ├── admin/
│   │   │   ├── page.tsx                    # Dashboard
│   │   │   └── restaurants/[id]/page.tsx   # Details
│   │   ├── layout.tsx
│   │   └── globals.css
│   ├── components/
│   │   └── admin/
│   │       ├── AdminLayout.tsx
│   │       ├── RestaurantList.tsx
│   │       ├── RestaurantCard.tsx
│   │       └── FeedbackList.tsx
│   ├── lib/
│   │   └── api.ts                          # API client
│   └── middleware.ts                       # Auth protection
```

## Security Considerations

### ⚠️ Important: Authentication Not Fully Implemented

The current implementation includes **placeholder authentication** that allows unauthorized access. This is intentional for development and integration testing.

**Before production deployment, you MUST:**

1. **Implement Token Retrieval**
   - Update admin pages to retrieve auth tokens from cookies
   - Example provided in code comments

2. **Update Middleware**
   - Add actual authentication checks
   - Verify session with backend
   - Redirect unauthorized users

3. **Configure Backend**
   - Implement `/api/auth/me` endpoint for session verification
   - Configure Auth0 login/logout endpoints
   - Set up session cookies

**See `docs/SECURITY.md` for detailed security implementation guide.**

### Security Features Included

- Middleware structure for route protection
- Server-side rendering (no client-side token exposure)
- Clear security warnings in code
- Documented authentication flow
- Environment variable configuration

## Integration with Backend

### Expected Backend Endpoints

#### Authentication (to be implemented)
- `GET /api/auth/me` - Verify session and return user
- `GET /api/auth/login` - Redirect to Auth0 login
- `GET /api/auth/logout` - Clear session and logout

#### Data (existing)
- `GET /restaurants` - List all restaurants (requires auth token)
- `GET /restaurants/:id` - Get restaurant details (requires auth token)
- `GET /feedbacks` - List all feedback (requires auth)

### Environment Variables

**Frontend** (`.env.local`):
```env
NEXT_PUBLIC_BACKEND_URL=http://localhost:3000
```

**Backend** (existing):
```env
AUTH0_DOMAIN=your-domain.auth0.com
AUTH0_CLIENT_ID=your-client-id
AUTH0_CLIENT_SECRET=your-secret
DATABASE_URL=postgresql://...
```

## Testing Instructions

### Local Setup

1. **Start Rails Backend**
   ```bash
   bundle install
   rails db:migrate
   rails server
   # Backend runs on http://localhost:3000
   ```

2. **Start Next.js Frontend**
   ```bash
   cd frontend
   npm install
   cp .env.local.example .env.local
   # Edit .env.local with backend URL
   npm run dev
   # Frontend runs on http://localhost:3001
   ```

3. **Access Admin Interface**
   - Navigate to http://localhost:3001/admin
   - Note: Without Auth0 configured, you'll see error states

### With Auth0 Backend (Future)

Once the backend Auth0 PR is merged:

1. Configure Auth0 credentials in backend
2. Start both backend and frontend
3. Visit http://localhost:3001/admin
4. Should redirect to Auth0 login
5. After login, should show restaurant dashboard

### Build Verification

```bash
cd frontend
npm run build
npm run lint
```

Both commands should complete successfully.

## Files Changed

### New Files
- `frontend/` - Entire Next.js application
  - `src/app/admin/page.tsx` - Admin dashboard
  - `src/app/admin/restaurants/[id]/page.tsx` - Restaurant details
  - `src/components/admin/` - All admin components
  - `src/lib/api.ts` - API client
  - `src/middleware.ts` - Auth middleware
- `docs/Admin.md` - Admin documentation
- `docs/SECURITY.md` - Security guide

### Modified Files
- `README.md` - Added admin section
- `.gitignore` - Added frontend ignore patterns

## Breaking Changes

None. This is a new feature addition that doesn't affect existing backend functionality.

## Migration Guide

Not applicable - this is a new feature.

## Performance Considerations

- **Server Components**: Reduce JavaScript bundle size
- **Static Generation**: Some pages can be pre-rendered
- **Optimized Images**: Next.js automatic image optimization
- **Code Splitting**: Automatic route-based splitting

## Future Enhancements

Possible improvements for future PRs:

- [ ] Create/Edit/Delete restaurant functionality
- [ ] Advanced filtering and sorting
- [ ] Analytics dashboard
- [ ] Real-time feedback notifications
- [ ] Export data to CSV
- [ ] User role management (admin vs. viewer)
- [ ] Feedback response system
- [ ] Restaurant menu preview

## Testing

### Manual Testing Completed
- ✅ Next.js builds successfully
- ✅ Linting passes without errors
- ✅ TypeScript compilation successful
- ✅ Responsive design verified
- ✅ Component rendering checked
- ✅ API client structure verified

### Automated Testing
- ⏸️ No automated tests added (no existing test infrastructure found)
- Future PR can add Jest/React Testing Library tests

## Documentation

- ✅ Comprehensive admin guide in `docs/Admin.md`
- ✅ Security considerations in `docs/SECURITY.md`
- ✅ README updated with quick start
- ✅ Code comments with TODOs for integration
- ✅ Environment variable documentation

## Deployment Considerations

### Frontend Deployment Options

**Option 1: Separate Deployment**
- Deploy to Vercel, Netlify, or similar
- Set `NEXT_PUBLIC_BACKEND_URL` environment variable
- Configure CORS on backend

**Option 2: Same Server as Backend**
- Build Next.js as static export
- Serve from Rails public directory
- Requires additional Rails configuration

### Environment Variables

Production deployment requires:
```env
NEXT_PUBLIC_BACKEND_URL=https://your-production-backend.com
```

## Checklist

- [x] Code follows repository style guidelines
- [x] Code builds without errors
- [x] Linting passes
- [x] TypeScript types are properly defined
- [x] Components are documented
- [x] Security considerations documented
- [x] README updated
- [x] TODO comments added for integration points
- [x] Environment variables documented
- [ ] Integration with backend tested (requires Auth0 PR)
- [ ] Production security checklist completed (will be done with Auth0 integration)

## Questions for Reviewers

1. **Auth0 Integration**: What's the timeline for the backend Auth0 PR? We should coordinate testing.

2. **Deployment Strategy**: Which option do you prefer for frontend deployment - separate or with backend?

3. **Additional Features**: Any must-have features before merging? (Current scope is read-only admin)

4. **UI/UX**: Any specific design requirements or branding guidelines to follow?

## Screenshots

*To be added after manual testing with live backend*

When backend is running, the admin interface shows:
- Restaurant listing with search
- Restaurant detail pages
- Feedback display
- Responsive layout on mobile/desktop

## Related PRs/Issues

- Related: Backend Auth0 PR (in qr-menu-ui repository)
- Future: Admin CRUD operations PR
- Future: Analytics dashboard PR

## Reviewers

Please review:
- Overall architecture and component structure
- Security implementation approach
- Documentation completeness
- Integration points with backend
- Code quality and TypeScript usage

---

**Note**: This PR provides the foundation for the admin backoffice. Full functionality requires the backend Auth0 authentication to be implemented and integrated.
