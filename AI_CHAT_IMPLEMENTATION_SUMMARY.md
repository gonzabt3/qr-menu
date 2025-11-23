# AI Chat Backend Implementation Summary

## Implementation Status: ✅ COMPLETE

This document summarizes the AI chat backend integration with vector embeddings for the qr-menu application.

## What Has Been Implemented

### 1. Dependencies (✅ Complete)
- **pgvector**: PostgreSQL extension for vector similarity search
- **sidekiq & redis**: Background job processing for embedding generation
- **ruby-openai**: OpenAI client library
- **HTTParty**: For DeepSeek API calls

### 2. Database Changes (✅ Complete)
- Migration created: `20251123170425_add_embedding_to_products.rb`
- Added `embedding vector(1536)` column to products table
- Added `embedding_generated_at` timestamp column
- Created ivfflat index for efficient vector similarity search
- Configured Rails to use SQL schema format (required for pgvector)

### 3. Models (✅ Complete)
- **Product model** (`app/models/product.rb`):
  - `combined_text_for_embedding` method: Composes searchable text from product attributes
  - `after_commit` hook: Automatically enqueues embedding jobs when products are created/updated
  - Feature flag protected: Only runs when `FEATURE_AI_CHAT_ENABLED=true`

### 4. Services (✅ Complete)
- **AiClient** (`app/services/ai_client.rb`): Main abstraction layer
  - Delegates to provider-specific implementations
  - Configurable via `AI_PROVIDER` environment variable

- **AiClient::Deepseak** (`app/services/ai_client/deepseak.rb`):
  - `embed(text)`: Generates embeddings using DeepSeek API
  - `complete(prompt, options)`: Generates chat completions
  - Full error handling and optional logging

- **AiClient::OpenAi** (`app/services/ai_client/open_ai.rb`):
  - `embed(text)`: Generates embeddings using OpenAI API  
  - `complete(prompt, options)`: Generates chat completions
  - Full error handling and optional logging

### 5. Background Jobs (✅ Complete)
- **ProductEmbeddingJob** (`app/jobs/product_embedding_job.rb`):
  - Sidekiq worker for generating product embeddings
  - Processes products asynchronously
  - Uses `Pgvector.encode()` for proper vector type handling
  - Retry logic with exponential backoff
  - Optional detailed logging

### 6. API Endpoint (✅ Complete)
- **Api::Ai::ChatsController** (`app/controllers/api/ai/chats_controller.rb`):
  - Endpoint: `POST /api/ai/chat`
  - Protected by `FEATURE_AI_CHAT_ENABLED` feature flag
  - Skips authentication for public access
  - Request format: `{ "user_query": "question text" }`
  - Response format: `{ "answer": "...", "references": [{product_id, name, price, description}] }`
  - Vector similarity search with top-5 results
  - Context-aware prompt construction
  - Full error handling

### 7. Rake Tasks (✅ Complete)
- **product_embeddings:backfill**: Enqueues jobs for products without embeddings
- **product_embeddings:regenerate**: Forces regeneration of all embeddings
- **product_embeddings:stats**: Shows embedding coverage statistics

### 8. Tests (✅ Complete)
- Request specs for chat endpoint (`spec/requests/api/ai/chats_spec.rb`):
  - Feature flag ON/OFF scenarios
  - Valid/invalid requests
  - Error handling
  
- Job specs (`spec/jobs/product_embedding_job_spec.rb`):
  - Successful embedding generation
  - Error scenarios
  - Edge cases

### 9. Documentation (✅ Complete)
- Updated README.md with:
  - AI chat feature description
  - Environment variable documentation
  - Setup instructions for pgvector
  - Sidekiq configuration
  - Usage examples
  - Testing instructions
  
- Created `.env.example` with all required variables

### 10. Configuration (✅ Complete)
- Routes configured for `/api/ai/chat`
- Sidekiq initializer created
- CORS initializer updated to handle missing env vars
- SQL schema format configured for pgvector support

## Environment Variables

### Required for AI Feature
```bash
# Feature flag (default: false)
FEATURE_AI_CHAT_ENABLED=true

# AI Provider selection (default: deepseak)
AI_PROVIDER=deepseak  # or openai

# API Keys (required based on provider)
DEEPSEAK_API_KEY=your_deepseak_api_key
OPENAI_API_KEY=your_openai_api_key

# Optional logging (default: false)
ENABLE_AI_CHAT_LOGS=true

# Redis for Sidekiq
REDIS_URL=redis://localhost:6379/0
```

## Setup Instructions

### 1. Database Setup
```bash
# Enable pgvector extension
psql -d your_database_name -c 'CREATE EXTENSION IF NOT EXISTS vector;'

# Run migrations
rails db:migrate
```

### 2. Start Background Workers
```bash
# In a separate terminal
bundle exec sidekiq
```

### 3. Generate Embeddings
```bash
# Backfill embeddings for existing products
rails product_embeddings:backfill

# Check progress
rails product_embeddings:stats
```

### 4. Test the Endpoint
```bash
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "¿qué puedo comer si soy vegano?"
  }'
```

## How It Works

1. **Embedding Generation**:
   - When a product is created/updated, `ProductEmbeddingJob` is enqueued
   - Job generates embedding from product text using AI provider
   - Embedding is stored in `products.embedding` column

2. **Chat Query Processing**:
   - User submits query to `/api/ai/chat`
   - Query is converted to embedding vector
   - Database performs similarity search using cosine distance
   - Top 5 similar products are retrieved
   - Context is built from product details
   - LLM generates response based on context
   - Response includes answer and product references

## Technical Details

### Vector Similarity Search
- Uses pgvector's ivfflat index
- Cosine distance operator: `<=>` 
- Index configuration: 100 lists
- Dimension: 1536 (standard for text-embedding-ada-002 and DeepSeek)

### Background Processing
- Sidekiq with Redis backend
- Retry logic: 3 attempts with exponential backoff
- Default queue: `default`

### Security & Privacy
- No conversation history stored by default
- Feature flag protection
- Public endpoint (no authentication required)
- API keys stored in environment variables

## Known Limitations

1. **Vector Type Handling**: Rails schema.rb doesn't fully support custom pgvector types. Solution: Using SQL schema format (`structure.sql`)

2. **Index Performance**: ivfflat index shows warning with small datasets. This is normal and performance improves with more data.

3. **Test Database**: Schema migrations require manual insertion of migration versions in test database.

## Future Enhancements

1. Add conversation history tracking (optional, privacy-conscious)
2. Implement caching for frequently asked questions
3. Add multi-language support
4. Implement rate limiting
5. Add analytics for query patterns
6. Support for HNSW index (when stable in production)

## Files Created/Modified

### Created Files
- `db/migrate/20251123170425_add_embedding_to_products.rb`
- `app/services/ai_client.rb`
- `app/services/ai_client/deepseak.rb`
- `app/services/ai_client/open_ai.rb`
- `app/jobs/product_embedding_job.rb`
- `app/controllers/api/ai/chats_controller.rb`
- `lib/tasks/product_embeddings.rake`
- `config/initializers/sidekiq.rb`
- `config/sidekiq.yml`
- `spec/requests/api/ai/chats_spec.rb`
- `spec/jobs/product_embedding_job_spec.rb`
- `.env.example`
- `db/structure.sql`

### Modified Files
- `Gemfile` - Added pgvector, sidekiq, redis, ruby-openai
- `app/models/product.rb` - Added embedding methods and hooks
- `config/routes.rb` - Added /api/ai/chat route
- `config/application.rb` - Configured SQL schema format
- `config/initializers/cors.rb` - Fixed nil handling
- `.gitignore` - Added exception for .env.example
- `README.md` - Added AI chat documentation

## Conclusion

The AI chat backend integration is **fully implemented and ready for use**. All core functionality is in place:
- ✅ Embedding generation with background jobs
- ✅ Vector similarity search
- ✅ AI-powered chat endpoint
- ✅ Configurable providers (DeepSeek/OpenAI)
- ✅ Feature flag protection
- ✅ Comprehensive documentation
- ✅ Test coverage

The implementation follows Rails best practices, includes proper error handling, and is production-ready pending final API key configuration and testing with real data.
