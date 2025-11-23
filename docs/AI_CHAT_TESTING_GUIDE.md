# AI Chat Testing Guide

## Overview
This document provides instructions for testing the AI chat feature locally and in production.

## Prerequisites

### 1. Enable pgvector Extension
Connect to your PostgreSQL database and run:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### 2. Run Migrations
```bash
rails db:migrate
```

### 3. Configure Environment Variables
Add to your `.env` file:

```bash
# For DeepSeek (default)
AI_PROVIDER=deepseek
DEEPSEEK_API_KEY=your_deepseek_key_here

# OR for OpenAI
AI_PROVIDER=openai
OPENAI_API_KEY=your_openai_key_here
```

### 4. Generate Embeddings
```bash
# Check current status
rails embeddings:status

# Backfill all products
rails embeddings:backfill

# Check status again
rails embeddings:status
```

## Testing the Chat Endpoint

### Basic Test
```bash
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "¿Tienen opciones veganas?",
    "menu_id": 1
  }'
```

### Test with Top-K Parameter
```bash
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_query": "comida italiana",
    "menu_id": 1,
    "top_k": 3
  }'
```

### Expected Response Format
```json
{
  "answer": "Sí, tenemos varias opciones veganas incluyendo la Ensalada Mediterránea...",
  "references": [
    {
      "product_id": 42,
      "name": "Ensalada Mediterránea",
      "description": "Ensalada fresca con vegetales orgánicos",
      "price": 12.50,
      "similarity_score": 0.8234,
      "is_vegan": true,
      "is_celiac": false
    }
  ]
}
```

## Running Tests

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test Suites
```bash
# Model tests
bundle exec rspec spec/models/product_spec.rb

# Job tests
bundle exec rspec spec/jobs/product_embedding_job_spec.rb

# Service tests
bundle exec rspec spec/services/

# Controller tests
bundle exec rspec spec/requests/chat_spec.rb
```

## Troubleshooting

### Issue: "AI service is not properly configured"
**Solution**: Check that you have set either `DEEPSEEK_API_KEY` or `OPENAI_API_KEY` environment variable.

### Issue: "No products found"
**Solution**: 
1. Check that embeddings have been generated: `rails embeddings:status`
2. Run backfill if needed: `rails embeddings:backfill`
3. Verify the menu_id exists in your database

### Issue: "Menu not found"
**Solution**: Verify the menu_id parameter matches an existing menu in your database.

### Issue: Jobs not processing
**Solution**: 
- Development: Jobs run inline by default
- Production: Ensure background job processor is running (e.g., `bundle exec sidekiq`)

## Rake Tasks Reference

### embeddings:backfill
Generates embeddings for all products that don't have them or have outdated ones.
```bash
rails embeddings:backfill
```

### embeddings:status
Shows current embedding generation status across all products.
```bash
rails embeddings:status
```

### embeddings:regenerate
Regenerates embeddings for specific products by ID.
```bash
rails embeddings:regenerate[1,2,3]
```

### embeddings:clear
Clears all embeddings (requires confirmation).
```bash
rails embeddings:clear
```

## Performance Considerations

- First-time setup: Embeddings are generated asynchronously. Wait for jobs to complete before testing.
- Query time: Vector similarity search typically takes 50-200ms depending on database size
- OpenAI embeddings: Costs ~$0.0001 per 1K tokens
- DeepSeek: Currently uses free pseudo-embeddings (deterministic, local generation)

## Integration with Frontend

The frontend should call this endpoint when users interact with the chat interface:

```javascript
const response = await fetch('/chat', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    user_query: userInput,
    menu_id: currentMenuId,
    top_k: 5 // optional
  })
});

const data = await response.json();
// data.answer contains the AI response
// data.references contains the matching products
```

## Production Deployment Checklist

- [ ] pgvector extension enabled in production database
- [ ] Migrations run
- [ ] Environment variables configured (AI_PROVIDER, API keys)
- [ ] Background job processor running (Sidekiq/etc)
- [ ] Embeddings backfill completed
- [ ] Test chat endpoint with production data
- [ ] Monitor job failures and API errors
