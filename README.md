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
* `FEEDBACK_READ_SECRET` - Secret token for accessing feedback list (optional)
* `MERCADO_PAGO_ACCESS_TOKEN` - MercadoPago API token
* Auth0 configuration variables

### AI Chat Feature (Optional)

The AI chat feature is optional and can be enabled via environment variables:

* `FEATURE_AI_CHAT_ENABLED` - Set to `true` to enable AI chat functionality (default: `false`)
* `AI_PROVIDER` - AI provider to use: `deepseak` or `openai` (default: `deepseak`)
* `DEEPSEAK_API_KEY` - API key for DeepSeek (required if using DeepSeek)
* `OPENAI_API_KEY` - API key for OpenAI (required if using OpenAI)
* `ENABLE_AI_CHAT_LOGS` - Set to `true` to enable detailed AI logging (default: `false`)
* `REDIS_URL` - Redis connection string for Sidekiq (default: `redis://localhost:6379/0`)

## Database creation

```bash
rails db:create
```

### Enable pgvector extension (required for AI chat)

If you plan to use the AI chat feature, you need to enable the pgvector extension in PostgreSQL:

```bash
psql -d your_database_name -c 'CREATE EXTENSION IF NOT EXISTS vector;'
```

Then run migrations:

```bash
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

### AI Chat API (Feature Flag Protected)

The AI chat feature uses embeddings stored in PostgreSQL with pgvector to provide intelligent responses about menu items.

#### Chat Endpoint

Ask questions about the menu and get AI-powered responses.

**Endpoint:** `POST /api/ai/chat`

**Feature Flag:** This endpoint requires `FEATURE_AI_CHAT_ENABLED=true` to be set.

**Request Body:**
```json
{
  "user_query": "¿qué puedo comer si soy vegano?"
}
```

**Success Response (200 OK):**
```json
{
  "answer": "Tenemos varias opciones veganas disponibles. Te recomiendo la Ensalada Verde que es fresca y completamente vegana, también el Hummus con vegetales...",
  "references": [
    {
      "product_id": 1,
      "name": "Ensalada Verde",
      "price": 12.50,
      "description": "Ensalada fresca con vegetales de temporada"
    },
    {
      "product_id": 5,
      "name": "Hummus con vegetales",
      "price": 8.00,
      "description": "Hummus casero servido con vegetales crudos"
    }
  ]
}
```

**Error Responses:**

- `400 Bad Request` - Missing user_query parameter
- `403 Forbidden` - Feature flag is disabled
- `500 Internal Server Error` - AI service error

**Example using curl:**
```bash
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "¿qué puedo comer si soy vegano?"
  }'
```

#### Setting up AI Chat

1. **Enable the feature flag:**
   ```bash
   export FEATURE_AI_CHAT_ENABLED=true
   ```

2. **Configure AI provider (DeepSeek or OpenAI):**
   ```bash
   # For DeepSeek (default)
   export AI_PROVIDER=deepseak
   export DEEPSEAK_API_KEY=your_deepseak_api_key
   
   # OR for OpenAI
   export AI_PROVIDER=openai
   export OPENAI_API_KEY=your_openai_api_key
   ```

3. **Enable detailed logging (optional):**
   ```bash
   export ENABLE_AI_CHAT_LOGS=true
   ```

4. **Start Redis and Sidekiq:**
   ```bash
   # Start Redis (in a separate terminal)
   redis-server
   
   # Start Sidekiq (in a separate terminal)
   bundle exec sidekiq
   ```

5. **Generate embeddings for existing products:**
   ```bash
   # Backfill embeddings for all products without embeddings
   bundle exec rails product_embeddings:backfill
   
   # Or regenerate all embeddings
   bundle exec rails product_embeddings:regenerate
   
   # Check embedding statistics
   bundle exec rails product_embeddings:stats
   ```

6. **Test the endpoint:**
   ```bash
   curl -X POST http://localhost:3000/api/ai/chat \
     -H "Content-Type: application/json" \
     -d '{"user_query": "¿qué puedo comer si soy vegano?"}'
   ```

**Note:** When the feature flag is enabled, embeddings are automatically generated for new products and updated products via background jobs.


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

## Deployment instructions

This application is configured for deployment on Render.com (see `render.yaml`).

1. Set all required environment variables
2. Deploy using Render's automatic deployment
3. Run migrations: `rails db:migrate`

