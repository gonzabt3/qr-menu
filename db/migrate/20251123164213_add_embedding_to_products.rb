class AddEmbeddingToProducts < ActiveRecord::Migration[7.1]
  def up
    # Enable pgvector extension
    enable_extension 'vector'

    # Add embedding column (1536 dimensions for OpenAI text-embedding-ada-002 and compatible models)
    add_column :products, :embedding, :vector, limit: 1536
    
    # Add timestamp to track when embedding was generated
    add_column :products, :embedding_generated_at, :datetime

    # Add index for vector similarity search using HNSW (Hierarchical Navigable Small World)
    # If HNSW is not available, falls back to IVFFlat
    # Note: For production, you may want to tune these parameters based on your data size
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_products_on_embedding 
      ON products USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    remove_index :products, name: 'index_products_on_embedding' if index_exists?(:products, :embedding, name: 'index_products_on_embedding')
    remove_column :products, :embedding_generated_at
    remove_column :products, :embedding
    disable_extension 'vector'
  end
end
