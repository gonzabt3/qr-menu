# QR Menu API

A Ruby on Rails API for managing restaurant menus with QR code functionality.

## Ruby version

* Ruby 3.3.0
* Rails 7.1.3+

## System dependencies

* PostgreSQL database with pgvector extension
* Ruby 3.3.0
* Redis (for Sidekiq background jobs)

## Configuration

Set up the following environment variables:

* `DATABASE_URL` - PostgreSQL database connection string (production)
* `REDIS_URL` - Redis connection string (default: redis://localhost:6379/0)
* `FEEDBACK_READ_SECRET` - Secret token for accessing feedback list (optional)
* `MERCADO_PAGO_ACCESS_TOKEN` - MercadoPago API token
* Auth0 configuration variables

### AI Chat Configuration (Optional)

The application includes an AI-powered chat feature for helping customers explore the menu. This feature is disabled by default and requires configuration:

#### Required Environment Variables

* `FEATURE_AI_CHAT_ENABLED` - Set to `true` to enable the AI chat feature (default: disabled)
* `AI_PROVIDER` - AI provider to use: `deepseak` (default) or `openai`
* `DEEPSEAK_API_KEY` - API key for DeepSeek (if using DeepSeek provider)
* `OPENAI_API_KEY` - API key for OpenAI (if using OpenAI provider)
* `ENABLE_AI_CHAT_LOGS` - Set to `true` to enable detailed logging (default: false)

#### pgvector Setup

The AI chat feature uses pgvector for storing and searching product embeddings. You need to enable the extension in your PostgreSQL database:

```sql
-- Run this SQL command in your database
CREATE EXTENSION IF NOT EXISTS vector;
```

For local development with PostgreSQL:
```bash
psql -d qr_menu_development -c 'CREATE EXTENSION IF NOT EXISTS vector;'
```

#### Background Jobs

The application uses Sidekiq for processing embedding generation jobs. Start Sidekiq:

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

Make sure Redis is running:
```bash
redis-server
```

## Database creation

```bash
rails db:create

# Enable pgvector extension (if using AI chat)
psql -d qr_menu_development -c 'CREATE EXTENSION IF NOT EXISTS vector;'

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
* AI-powered menu chat assistant (optional, feature flag controlled)

## AI Chat Feature

The application includes an AI-powered chat assistant that helps customers discover menu items based on their preferences (e.g., "What can I eat if I'm vegan?").

### How it works

1. **Embeddings Generation**: When products are created or updated (and the feature is enabled), the system generates semantic embeddings using the configured AI provider (DeepSeek or OpenAI).

2. **Vector Search**: User queries are converted to embeddings and matched against product embeddings using pgvector's similarity search.

3. **AI Response**: The most relevant products are sent to the AI provider along with the user query to generate a helpful, contextual response.

### Backfill Embeddings

If you enable the AI chat feature on an existing database with products, run the backfill task to generate embeddings for all existing products:

```bash
# Make sure Sidekiq is running
bundle exec sidekiq -C config/sidekiq.yml

# In another terminal, run the backfill task
FEATURE_AI_CHAT_ENABLED=true rails product_embeddings:backfill
```

### API Endpoint

**Endpoint:** `POST /api/ai/chat`

**Request Body:**
```json
{
  "user_query": "¿qué puedo comer si soy vegano?",
  "session_id": "optional-session-id",
  "locale": "es"
}
```

**Response (200 OK):**
```json
{
  "answer": "Te recomiendo la Ensalada Vegana, que es completamente vegana y fresca con ingredientes orgánicos...",
  "references": [
    {
      "product_id": 123,
      "name": "Ensalada Vegana",
      "score": 0.15
    }
  ],
  "session_id": "generated-or-provided-session-id"
}
```

**Error Responses:**
- `404 Not Found` - Feature is not enabled (FEATURE_AI_CHAT_ENABLED != true)
- `400 Bad Request` - Missing or invalid user_query parameter
- `500 Internal Server Error` - Error processing the request

**Example using curl:**
```bash
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "¿qué puedo comer si soy vegano?",
    "locale": "es"
  }'
```

### Privacy & Data Storage

- User queries are **not stored** in the database by default
- When `ENABLE_AI_CHAT_LOGS=true`, only metadata is logged (query hash, timestamp, product references) - not the actual query text
- Session IDs are ephemeral and only used for request tracking
- Product embeddings are stored in the database for similarity search

### Testing the AI Chat Locally

1. Enable pgvector extension in your database:
   ```bash
   psql -d qr_menu_development -c 'CREATE EXTENSION IF NOT EXISTS vector;'
   ```

2. Run migrations:
   ```bash
   rails db:migrate
   ```

3. Set up environment variables in `.env`:
   ```
   FEATURE_AI_CHAT_ENABLED=true
   AI_PROVIDER=openai
   OPENAI_API_KEY=your-api-key-here
   ENABLE_AI_CHAT_LOGS=true
   REDIS_URL=redis://localhost:6379/0
   ```

4. Start Redis and Sidekiq:
   ```bash
   redis-server &
   bundle exec sidekiq -C config/sidekiq.yml &
   ```

5. Generate embeddings for existing products:
   ```bash
   rails product_embeddings:backfill
   ```

6. Start the Rails server:
   ```bash
   rails server
   ```

7. Test the endpoint:
   ```bash
   curl -X POST http://localhost:3000/api/ai/chat \
     -H "Content-Type: application/json" \
     -d '{"user_query":"¿qué puedo comer si soy vegano?"}'
   ```

## Deployment instructions

This application is configured for deployment on Render.com (see `render.yaml`).

1. Set all required environment variables
2. Deploy using Render's automatic deployment
3. Run migrations: `rails db:migrate`

