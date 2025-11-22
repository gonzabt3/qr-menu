# Admin Backoffice Documentation

## Overview

The QR Menu Admin Backoffice is a Next.js frontend application that provides a protected admin area for managing restaurants and viewing customer feedback. It integrates with the Rails API backend using Auth0 server-side authentication.

## Features

- **Restaurant Management**: View a paginated list of all restaurants with search functionality
- **Restaurant Details**: View detailed information about individual restaurants
- **Feedback Viewing**: Browse customer feedback for each restaurant
- **Protected Routes**: All admin pages require authentication via Auth0
- **Responsive Design**: Mobile-friendly interface using Tailwind CSS

## Architecture

The admin UI is built with:
- **Next.js 15** (App Router)
- **TypeScript** for type safety
- **Tailwind CSS** for styling
- **Server-side rendering** for better performance and SEO

## Setup Instructions

### Prerequisites

1. Ruby on Rails backend running (this repository)
2. Backend configured with Auth0 authentication (when the Auth0 PR is merged)
3. Node.js 18+ and npm installed

### Installation

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Create environment configuration:
```bash
cp .env.local.example .env.local
```

4. Edit `.env.local` and configure the backend URL:
```env
NEXT_PUBLIC_BACKEND_URL=http://localhost:3000
```

For production, set this to your deployed backend URL.

### Running Locally

1. Start the Rails backend (from the repository root):
```bash
bundle install
rails db:migrate
rails server
```

2. In a separate terminal, start the Next.js frontend:
```bash
cd frontend
npm run dev
```

3. Open your browser and navigate to `http://localhost:3001/admin`

### Building for Production

```bash
cd frontend
npm run build
npm start
```

## Configuration

### Environment Variables

#### Required

- `NEXT_PUBLIC_BACKEND_URL`: URL of the Rails API backend (default: `http://localhost:3000`)

#### Optional (if using Auth0 SDK directly)

- `NEXT_PUBLIC_AUTH0_DOMAIN`: Your Auth0 domain
- `NEXT_PUBLIC_AUTH0_CLIENT_ID`: Your Auth0 client ID
- `NEXT_PUBLIC_AUTH0_CALLBACK_URL`: Auth0 callback URL

**Note**: The current implementation relies on backend session-based authentication. You may not need Auth0 client-side configuration if the backend handles all auth flows.

## Authentication Flow

### How It Works

1. User visits `/admin` page
2. Frontend checks for authentication (TODO: needs backend implementation)
3. If not authenticated, user is redirected to backend's Auth0 login endpoint
4. After successful login, backend creates a session cookie
5. Frontend makes API requests with session cookie for authentication
6. Logout clears the session via backend endpoint

### Implementation Notes

The current implementation includes TODO comments where authentication needs to be integrated:

- **Token/Session Management**: The backend needs to provide a way to verify session status
- **Auth Endpoints**: The backend should expose:
  - `GET /api/auth/me` - Returns current user info or 401 if not authenticated
  - `GET /api/auth/login` - Redirects to Auth0 login
  - `GET /api/auth/logout` - Clears session and logs out

### Adapting to Your Backend

1. **Update API client** (`src/lib/api.ts`):
   - Modify `checkAuth()` to call your backend's session verification endpoint
   - Update `getLoginUrl()` and `getLogoutUrl()` with correct backend endpoints

2. **Update admin pages** (`src/app/admin/page.tsx` and `src/app/admin/restaurants/[id]/page.tsx`):
   - Implement proper token/session retrieval from cookies
   - Add server-side authentication checks

3. **Add middleware** (optional):
   - Create `src/middleware.ts` to protect admin routes at the Next.js level
   - Redirect unauthenticated users before reaching page components

## API Integration

### Backend Endpoints Used

The frontend expects these endpoints from the Rails backend:

#### Authentication
- `GET /api/auth/me` - Verify session and get current user
- `GET /api/auth/login` - Redirect to Auth0 login
- `GET /api/auth/logout` - Clear session

#### Restaurants
- `GET /restaurants` - List all restaurants (requires Auth0 token)
- `GET /restaurants/:id` - Get restaurant details (requires Auth0 token)

#### Feedback
- `GET /feedbacks` - List all feedback (currently uses secret header)
- `GET /restaurants/:id/feedback` - Get feedback for specific restaurant (needs implementation)

### API Client

The API client is located at `src/lib/api.ts` and provides:

- Type-safe API methods
- Centralized error handling
- Configurable backend URL
- Token/session management helpers

## Pages Structure

```
frontend/src/app/
├── admin/
│   ├── page.tsx                    # Admin dashboard (restaurant list)
│   └── restaurants/
│       └── [id]/
│           └── page.tsx            # Restaurant detail page with feedback
├── layout.tsx                       # Root layout
└── page.tsx                        # Main site homepage
```

## Components

### AdminLayout
Provides consistent layout with header, navigation, and logout button.

**Location**: `src/components/admin/AdminLayout.tsx`

### RestaurantList
Displays paginated, searchable list of restaurants.

**Features**:
- Search by name, address, or description
- Pagination (10 items per page)
- Responsive grid layout

**Location**: `src/components/admin/RestaurantList.tsx`

### RestaurantCard
Displays individual restaurant in card format with key information.

**Location**: `src/components/admin/RestaurantCard.tsx`

### FeedbackList
Shows customer feedback items with user info and timestamps.

**Location**: `src/components/admin/FeedbackList.tsx`

## Development Notes

### Adding New Features

1. **New Admin Pages**: Create them under `src/app/admin/`
2. **New Components**: Add to `src/components/admin/`
3. **API Methods**: Extend `src/lib/api.ts`

### Styling

The UI uses Tailwind CSS with a clean, minimal design. Colors:
- Primary: Blue (#2563eb)
- Success: Green
- Error: Red (#dc2626)
- Background: Gray-50

### TypeScript Types

Type definitions are in `src/lib/api.ts`:
- `Restaurant`: Restaurant data structure
- `Feedback`: Feedback item structure
- `User`: User/auth information

## Testing

Currently, no tests are implemented. To add tests:

1. Install testing dependencies:
```bash
npm install --save-dev @testing-library/react @testing-library/jest-dom jest jest-environment-jsdom
```

2. Create test files alongside components (e.g., `RestaurantList.test.tsx`)

3. Run tests:
```bash
npm test
```

## Deployment

### Option 1: Deploy with Backend

Deploy the frontend as a static Next.js app alongside your Rails backend.

### Option 2: Separate Deployment

Deploy to Vercel, Netlify, or another platform:

1. Build the app:
```bash
npm run build
```

2. Set environment variables in your deployment platform:
```
NEXT_PUBLIC_BACKEND_URL=https://your-backend.com
```

3. Deploy the `frontend/` directory

## Troubleshooting

### "API Error: 401"
- Ensure you're logged in via the backend
- Check that the backend session cookies are being sent
- Verify Auth0 configuration on the backend

### "Failed to fetch restaurants"
- Confirm the backend is running
- Check `NEXT_PUBLIC_BACKEND_URL` is correct
- Verify CORS is configured on the backend to allow requests from the frontend domain

### Build Errors
- Run `npm install` to ensure all dependencies are installed
- Check Node.js version (requires 18+)
- Clear `.next` directory: `rm -rf .next && npm run build`

## Security Considerations

- All admin routes require authentication
- API requests include auth tokens/session cookies
- No sensitive data is stored in client-side code
- Environment variables are properly prefixed with `NEXT_PUBLIC_` for client-side access

## Future Enhancements

Potential improvements:
- Add create/edit/delete functionality for restaurants
- Implement real-time feedback notifications
- Add analytics dashboard
- Export data to CSV
- Advanced filtering and sorting options
- User role management (admin vs. viewer)

## Support

For issues or questions:
1. Check this documentation
2. Review TODO comments in the code
3. Open an issue in the GitHub repository
