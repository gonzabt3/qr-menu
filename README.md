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

### Product Tap Metrics API

Track and analyze product engagement through tap events.

#### Record Product Tap

Record when a user views/taps on a product. This endpoint does not require authentication.

**Endpoint:** `POST /metrics/product-tap`

**Request Body:**
```json
{
  "product_id": 123,
  "session_identifier": "unique-session-id"
}
```

Or with authenticated user:
```json
{
  "product_id": 123,
  "user_id": 456
}
```

**Parameters:**
- `product_id` (required) - ID of the product being tapped
- `session_identifier` (optional) - Unique session identifier for anonymous users
- `user_id` (optional) - User ID for authenticated users

**Note:** Either `session_identifier` or `user_id` must be provided.

**Success Response (201 Created):**
```json
{
  "message": "Product tap recorded successfully",
  "tap": {
    "id": 1,
    "product_id": 123,
    "user_id": null,
    "session_identifier": "unique-session-id",
    "created_at": "2024-11-25T22:30:00.000Z"
  }
}
```

**Error Responses:**

- `404 Not Found` - Product not found
```json
{
  "error": "Product not found"
}
```

- `422 Unprocessable Entity` - Validation error
```json
{
  "errors": ["Session identifier can't be blank"]
}
```

**Example using curl:**
```bash
curl -X POST http://localhost:3000/metrics/product-tap \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 123,
    "session_identifier": "abc-123-xyz"
  }'
```

#### Get Product Tap Dashboard

Retrieve aggregated metrics and analytics for product taps. This endpoint does not require authentication.

**Endpoint:** `GET /metrics/product-taps`

**Success Response (200 OK):**
```json
{
  "total_taps": 150,
  "taps_by_product": [
    {
      "product_id": 123,
      "product_name": "Pizza Margherita",
      "count": 45
    },
    {
      "product_id": 124,
      "product_name": "Caesar Salad",
      "count": 30
    }
  ],
  "recent_taps": [
    {
      "id": 150,
      "product_id": 123,
      "product_name": "Pizza Margherita",
      "user_id": 5,
      "session_identifier": null,
      "created_at": "2024-11-25T22:30:00.000Z"
    }
  ],
  "top_products": [
    {
      "product_id": 123,
      "product_name": "Pizza Margherita",
      "tap_count": 45
    }
  ]
}
```

**Response Fields:**
- `total_taps` - Total number of tap events recorded
- `taps_by_product` - Array of tap counts grouped by product (ordered by count descending)
- `recent_taps` - Array of the 50 most recent tap events (ordered by date descending)
- `top_products` - Array of top 10 most-tapped products

**Example using curl:**
```bash
curl -X GET http://localhost:3000/metrics/product-taps
```

## Data Storage

### Feedback Table

Feedback data is stored in the PostgreSQL database in the `feedbacks` table with the following schema:

- `id` (BIGINT) - Primary key (auto-incremented)
- `message` (TEXT) - Feedback message content
- `created_at` (TIMESTAMP) - When the feedback was created
- `updated_at` (TIMESTAMP) - When the feedback was last updated

### Product Taps Table

Product tap events are stored in the `product_taps` table with the following schema:

- `id` (BIGINT) - Primary key (auto-incremented)
- `product_id` (BIGINT) - Foreign key to products table (required)
- `user_id` (BIGINT) - Foreign key to users table (optional, for authenticated users)
- `session_identifier` (STRING) - Session identifier (optional, for anonymous users)
- `created_at` (TIMESTAMP) - When the tap event occurred
- `updated_at` (TIMESTAMP) - When the record was last updated

Indexes are created on `product_id`, `user_id`, `session_identifier`, and `created_at` for efficient querying.

## Services

* QR code generation for restaurant menus
* User feedback collection
* MercadoPago payment integration
* Auth0 authentication

## Deployment instructions

This application is configured for deployment on Render.com (see `render.yaml`).

1. Set all required environment variables
2. Deploy using Render's automatic deployment
3. Run migrations: `rails db:migrate`

