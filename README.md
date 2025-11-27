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
* **AI-powered chat with semantic search** (new)

## AI Chat Feature

This application includes an AI-powered chat feature that uses vector embeddings and RAG (Retrieval Augmented Generation) to help customers find menu items and answer questions about the menu.

### Prerequisites

1. **PostgreSQL with pgvector extension**
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

2. **AI Provider API Key**
   - For DeepSeek (default): Set `DEEPSEEK_API_KEY`
   - For OpenAI: Set `OPENAI_API_KEY` and `AI_PROVIDER=openai`

### Environment Variables

Add these to your `.env` file:

```bash
# AI Configuration
AI_PROVIDER=deepseek              # Options: 'deepseek' (default) or 'openai'
DEEPSEEK_API_KEY=your_key_here   # Required if using DeepSeek
OPENAI_API_KEY=your_key_here     # Required if using OpenAI
```

### Setup Instructions

1. **Install dependencies**
   ```bash
   bundle install
   ```

2. **Run migrations**
   ```bash
   rails db:migrate
   ```
   This will:
   - Enable the pgvector extension
   - Add embedding column to products table
   - Create vector similarity search index

3. **Generate embeddings for existing products**
   ```bash
   rails embeddings:backfill
   ```
   This enqueues background jobs to generate embeddings for all products.

4. **Check embedding status**
   ```bash
   rails embeddings:status
   ```

### How It Works

1. **Automatic Embedding Generation**: When a product is created or updated, an embedding is automatically generated from its name, description, dietary attributes, and price.

2. **Vector Search**: User queries are converted to embeddings and compared against product embeddings using cosine similarity.

3. **RAG Response**: The most similar products are used as context for an AI model to generate natural, helpful responses.

### API Endpoint

**POST /chat**

Request body:
```json
{
  "user_query": "¿Tienen opciones veganas?",
  "menu_id": 1,
  "locale": "es",
  "top_k": 5
}
```

Response:
```json
{
  "answer": "Sí, tenemos varias opciones veganas...",
  "references": [
    {
      "product_id": 42,
      "name": "Ensalada Mediterránea",
      "description": "Ensalada fresca con...",
      "price": 12.50,
      "similarity_score": 0.8234,
      "is_vegan": true,
      "is_celiac": false
    }
  ]
}
```

### Rake Tasks

- `rails embeddings:backfill` - Generate embeddings for all products
- `rails embeddings:status` - Show current embedding status
- `rails embeddings:regenerate[1,2,3]` - Regenerate specific products by ID
- `rails embeddings:clear` - Clear all embeddings (requires confirmation)

### Testing the Chat Locally

```bash
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "¿Qué platos vegetarianos tienen?",
    "menu_id": 1
  }'
```

### Background Jobs

The application uses ActiveJob for asynchronous embedding generation. Make sure you have a job processor running:

For development (inline processing):
```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :inline
```

For production with Sidekiq:
```bash
bundle exec sidekiq
```

### Switching AI Providers

To switch from DeepSeek to OpenAI:
```bash
export AI_PROVIDER=openai
export OPENAI_API_KEY=your_openai_key
rails embeddings:clear  # Optional: clear existing embeddings
rails embeddings:backfill
```

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

