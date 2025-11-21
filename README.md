# QR Menu API

A Ruby on Rails API for managing restaurant menus with QR code functionality.

## Ruby version

* Ruby 3.3.0
* Rails 7.1.3+

## System dependencies

* PostgreSQL database
* Ruby 3.3.0

## Configuration

Set up the following environment variables:

* `DATABASE_URL` - PostgreSQL database connection string (production)
* `FEEDBACK_READ_SECRET` - Secret token for accessing feedback list (optional)
* `MERCADO_PAGO_ACCESS_TOKEN` - MercadoPago API token
* Auth0 configuration variables

## Database creation

```bash
rails db:create
rails db:migrate
```

## Database initialization

```bash
rails db:seed
```

## How to run the test suite

```bash
bundle install
rspec
```

## API Endpoints

### Feedback API

#### Submit Feedback

Submit user feedback about the application.

**Endpoint:** `POST /api/feedback`

**Request Body:**
```json
{
  "feedback": {
    "message": "Your feedback message here"
  }
}
```

**Validation:**
- `message` is required
- `message` maximum length is 2000 characters

**Success Response (201 Created):**
```json
{
  "id": 1,
  "message": "Your feedback message here",
  "createdAt": "2024-11-21T05:13:20.000Z"
}
```

**Error Response (400 Bad Request):**
```json
{
  "errors": ["Message can't be blank"]
}
```

**Example using curl:**
```bash
curl -X POST http://localhost:3000/api/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "feedback": {
      "message": "Great app! Love the QR menu feature."
    }
  }'
```

#### List All Feedbacks (Admin)

Retrieve submitted feedbacks (limited to 1000 most recent). This endpoint is protected and requires authentication.

**Endpoint:** `GET /api/feedbacks`

**Limits:** Returns up to 1000 most recent feedbacks, ordered by creation date (newest first).

**Authentication:**

Set the `FEEDBACK_READ_SECRET` environment variable and provide it in one of two ways:

1. As a header: `X-Feedback-Secret: your_secret_here`
2. As a query parameter: `?secret=your_secret_here`

**Success Response (200 OK):**
```json
[
  {
    "id": 3,
    "message": "Latest feedback",
    "createdAt": "2024-11-21T05:13:20.000Z"
  },
  {
    "id": 2,
    "message": "Earlier feedback",
    "createdAt": "2024-11-20T03:10:15.000Z"
  }
]
```

**Error Responses:**

- `401 Unauthorized` - Invalid or missing secret
- `503 Service Unavailable` - FEEDBACK_READ_SECRET not configured

**Example using curl:**
```bash
# Using header
curl -X GET http://localhost:3000/api/feedbacks \
  -H "X-Feedback-Secret: your_secret_here"

# Using query parameter
curl -X GET "http://localhost:3000/api/feedbacks?secret=your_secret_here"
```

## Data Storage

Feedback data is stored in the PostgreSQL database in the `feedbacks` table with the following schema:

- `id` (BIGINT) - Primary key (auto-incremented)
- `message` (TEXT) - Feedback message content
- `created_at` (TIMESTAMP) - When the feedback was created
- `updated_at` (TIMESTAMP) - When the feedback was last updated

## Services

* QR code generation for restaurant menus
* User feedback collection
* MercadoPago payment integration
* Auth0 authentication

## Admin Backoffice

This repository now includes a Next.js frontend admin backoffice for managing restaurants and viewing feedback.

### Quick Start

```bash
cd frontend
npm install
npm run dev
```

The admin interface will be available at `http://localhost:3001/admin`

For detailed setup instructions, authentication configuration, and API integration, see [docs/Admin.md](docs/Admin.md).

## Deployment instructions

This application is configured for deployment on Render.com (see `render.yaml`).

1. Set all required environment variables
2. Deploy using Render's automatic deployment
3. Run migrations: `rails db:migrate`

