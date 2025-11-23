class AddEmbeddingToProducts < ActiveRecord::Migration[7.1]
  def change
    # Enable pgvector extension if not already enabled
    enable_extension 'vector' unless extension_enabled?('vector')
    
    # Add embedding column (vector with 1536 dimensions for OpenAI/DeepSeek embeddings)
    add_column :products, :embedding, :vector, limit: 1536
    
    # Add timestamp to track when embedding was generated
    add_column :products, :embedding_generated_at, :timestamptz
    
    # Add HNSW index for fast vector similarity search
    # HNSW (Hierarchical Navigable Small World) is optimized for nearest neighbor search
    add_index :products, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
