class AddEmbeddingToProducts < ActiveRecord::Migration[7.1]
  def up
    # Enable pgvector extension if not already enabled
    enable_extension 'vector' unless extension_enabled?('vector')
    
    # Add embedding column (vector with 1536 dimensions for OpenAI/DeepSeek embeddings)
    add_column :products, :embedding, :vector, limit: 1536
    
    # Add timestamp to track when embedding was generated
    add_column :products, :embedding_generated_at, :timestamptz
    
    # Note: pgvector specialized indexes (ivfflat, hnsw) can be added later once products have embeddings
    # For now, we'll rely on sequential scan which works fine for smaller datasets
    # To add index later, run: CREATE INDEX ON products USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
  end
  
  def down
    remove_column :products, :embedding_generated_at
    remove_column :products, :embedding
  end
end
