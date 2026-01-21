# QR Menu Copilot Instructions

## Architecture Overview

This is a **monorepo with two independent applications**:

- **qr-menu** (Rails 7.1.3 API): Backend REST API with PostgreSQL, Auth0, AWS S3, and MercadoPago integration
- **qr-menu-ui** (Next.js 14): Frontend React application with TypeScript, Chakra UI, and Auth0

Both apps are deployed independently to Render (see `render.yaml` configs).

### Data Model Hierarchy
```
User → Restaurant → Menu → Section → Product
```
- Users authenticated via Auth0 (JWT tokens)
- Sections have `order` field for sorting (default scope)
- Products can have images stored in S3 (auto-deleted on destroy)

## Authentication Pattern

**Backend** (`Secured` concern):
- All controllers inherit `ApplicationController` which includes `Secured` concern
- `authorize` before_action extracts JWT from `Authorization: Bearer <token>` header
- Auto-creates users on first request using Auth0 email claim: `https://qr-menu.io/claims/email`
- Sets `@current_user` and `@decoded_token` for use in controllers
- Exception: `PublicController` skips authentication

**Frontend**:
- Auth0React provider wraps app in `src/pages/_app.tsx`
- All API calls use `getAccessTokenSilently()` to fetch tokens
- API base URL: `process.env.NEXT_PUBLIC_API_URL` (defined in `.env`)

## Development Workflow

### Running the Backend
```bash
cd qr-menu
bundle install
rails db:create db:migrate db:seed
rails server -p 3000
```

### Running the Frontend
```bash
cd qr-menu-ui
npm install
npm run dev  # runs on port 3001
```

### Testing
**Backend**: `rspec` (uses RSpec with FactoryBot, request specs in `spec/requests/`)
**Frontend**: `npm test` (Jest configured, tests in `src/hooks/*.test.ts`)

## Key Conventions

### API Response Format
- Use camelCase for JSON keys (e.g., `createdAt`, not `created_at`)
- Error responses: `{ errors: ["Message here"] }` with appropriate HTTP status
- Success responses include relevant object with 200/201 status

### Controller Patterns
- Nested resources follow Rails conventions: `/restaurants/:restaurant_id/menus/:id`
- Custom routes for special cases (e.g., `menus/by_name/:name`)
- Use `constraints: { id: /.*/ }` for email-based routes (allows dots in param)

### Frontend Service Layer
- All API calls in `src/services/*.ts` (menu.ts, product.ts, restaurant.ts, etc.)
- Services receive token as first param: `createMenu(token, restaurantId, values)`
- Custom hooks in `src/hooks/` encapsulate Auth0 + data fetching (e.g., `useMenu`, `useProduct`)

### Environment Variables
**Backend**: Use `dotenv-rails` (dev/test only), production uses Render env vars
**Frontend**: All public vars prefixed with `NEXT_PUBLIC_` (see `.env` file)

## Special Features

### QR Code Generation
- Uses `rqrcode` gem (backend) and `react-qr-code` (frontend)
- WiFi QR codes: `GET /qr/wifi` endpoint + `WiFiQRService` + `WiFiQRModal` component

### Image Upload
- Products use S3 for image storage
- `before_destroy` callback in Product model deletes S3 objects
- S3 path pattern: `menus/{menu_id}/products/{product_id}.{extension}`

### Payment Integration
- MercadoPago SDK integrated (backend gem + frontend React SDK)
- Webhook handler in separate `qr-menu-webhooks` service (see render.yaml)

### Admin Features
- Google Places integration for business data (`GooglePlacesService`, see `README_ADMIN_GOOGLE_PLACES.md`)
- Admin namespace controllers (e.g., `admin/businesses_controller.rb`)

## File Locations Reference
- Models: `qr-menu/app/models/`
- Controllers: `qr-menu/app/controllers/`
- Services: `qr-menu/app/services/` (S3, WiFiQR, GooglePlaces)
- Routes: `qr-menu/config/routes.rb`
- Frontend pages: `qr-menu-ui/src/pages/`
- Frontend components: `qr-menu-ui/src/components/`
- Frontend hooks: `qr-menu-ui/src/hooks/`
- Frontend services: `qr-menu-ui/src/services/`

## Testing Patterns
- Request specs test full HTTP cycle with JSON responses
- Use FactoryBot for test data (see `spec/factories/`)
- Frontend: Jest tests for hooks, Cypress for E2E (see `cypress/e2e/`)
