# AI Chat Architecture Overview

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend Client                          │
│  (Sends user query + menu_id to backend)                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ChatController                              │
│  POST /chat                                                      │
│  1. Validates input (user_query, menu_id)                       │
│  2. Generates query embedding via AiClient                       │
│  3. Finds similar products via vector search                     │
│  4. Builds RAG prompt with context                               │
│  5. Gets LLM response via AiClient                               │
│  6. Returns answer + product references                          │
└─────────┬──────────────────────────────┬────────────────────────┘
          │                              │
          ▼                              ▼
┌──────────────────────┐      ┌──────────────────────┐
│     AiClient         │      │  PostgreSQL + vector │
│  (Provider Factory)  │      │  - Products table    │
│                      │      │  - embedding column  │
│  ├─ DeepSeek        │      │  - IVFFlat index     │
│  │  (pseudo-embed)  │      │                      │
│  └─ OpenAI          │      │  Vector Similarity:  │
│     (real API)      │      │  embedding <=> query │
└──────────────────────┘      └──────────────────────┘
```

## Product Embedding Generation Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Product Create/Update                                        │
│  (name, description, price, is_vegan, is_celiac changed)    │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  Product Model                                                │
│  after_commit callback                                        │
│  - Detects relevant field changes                            │
│  - Enqueues ProductEmbeddingJob                              │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  ProductEmbeddingJob (Async)                                  │
│  1. Get product.combined_text_for_embedding                   │
│  2. Call AiClient.instance.embed(text)                        │
│  3. Store embedding + timestamp in DB                         │
│  4. Retry on ApiError, discard on ConfigurationError         │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  AiClient                                                      │
│  - DeepSeek: Generates deterministic pseudo-embedding         │
│  - OpenAI: Calls text-embedding-ada-002 API                   │
└─────────────────────┬────────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│  Product.update_columns                                        │
│  - embedding: [1536 floats]                                   │
│  - embedding_generated_at: timestamp                          │
└──────────────────────────────────────────────────────────────┘
```

## RAG (Retrieval Augmented Generation) Process

```
User Query: "¿Tienen opciones veganas?"
         │
         ▼
┌────────────────────────────────────────┐
│  1. Generate Query Embedding           │
│     AiClient.embed(query)              │
│     → [1536 floats]                    │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  2. Vector Similarity Search           │
│     SELECT * FROM products             │
│     WHERE embedding IS NOT NULL        │
│     ORDER BY embedding <=> query       │
│     LIMIT 5                            │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  3. Retrieved Products (Top-5)         │
│     - Ensalada Vegana (score: 0.82)   │
│     - Hamburguesa Vegetal (0.75)      │
│     - Bowl Buddha (0.71)               │
│     ...                                │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  4. Build RAG Prompt                   │
│  System: "Eres un asistente..."       │
│  Context: "Productos relevantes:       │
│    1. Ensalada Vegana - $12.50        │
│       (vegano, apto para celíacos)    │
│    2. ..."                             │
│  Query: "¿Tienen opciones veganas?"   │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  5. LLM Completion                     │
│     AiClient.complete(prompt)          │
│     → "Sí, tenemos varias opciones..." │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  6. Return Response                    │
│  {                                     │
│    "answer": "Sí, tenemos...",         │
│    "references": [                     │
│      { product_id, name, price, ... }  │
│    ]                                   │
│  }                                     │
└────────────────────────────────────────┘
```

## Database Schema

```sql
-- Products table
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR,
  description TEXT,
  price DECIMAL,
  section_id BIGINT REFERENCES sections(id),
  is_vegan BOOLEAN DEFAULT false,
  is_celiac BOOLEAN DEFAULT false,
  image_url VARCHAR,
  
  -- AI Chat columns
  embedding VECTOR(1536),
  embedding_generated_at TIMESTAMP,
  
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Vector similarity index
CREATE INDEX ON products 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

## Configuration Options

```bash
# Environment Variables
AI_PROVIDER=deepseek          # or 'openai'
DEEPSEEK_API_KEY=sk-...       # Required for DeepSeek
OPENAI_API_KEY=sk-...          # Required for OpenAI
```

## Key Design Decisions

1. **Provider Abstraction**: Factory pattern allows easy switching between AI providers
2. **Pseudo-Embeddings for DeepSeek**: Cost-effective alternative until real embedding API available
3. **Async Job Processing**: Prevents blocking product creation/updates
4. **Parameterized Queries**: Security-first approach for vector similarity search
5. **RAG Pattern**: Combines retrieval with generation for accurate, contextual responses
6. **Top-K Retrieval**: Limits context to most relevant products (configurable)

## Error Handling

```ruby
# ProductEmbeddingJob
retry_on AiClient::ApiError          # Transient errors (rate limits, timeouts)
discard_on AiClient::ConfigurationError  # Permanent errors (missing API key)

# ChatController
rescue AiClient::ConfigurationError  # 503 Service Unavailable
rescue AiClient::ApiError            # 503 Service Unavailable  
rescue StandardError                 # 500 Internal Server Error
```

## Performance Characteristics

- **Embedding Generation**: 100-500ms per product (OpenAI), instant (DeepSeek)
- **Vector Search**: 50-200ms for 10K products with IVFFlat index
- **LLM Completion**: 1-3 seconds depending on provider
- **Total Chat Response**: 2-4 seconds end-to-end

## Scalability Considerations

- **Index Tuning**: Adjust `lists` parameter based on product count
- **Caching**: Consider caching frequent queries
- **Rate Limiting**: Implement on chat endpoint for production
- **Batch Processing**: Backfill uses background jobs for large datasets
- **Provider Costs**: DeepSeek free (pseudo), OpenAI ~$0.0001/1K tokens
