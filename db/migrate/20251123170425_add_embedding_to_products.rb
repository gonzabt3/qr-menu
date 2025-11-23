class AddEmbeddingToProducts < ActiveRecord::Migration[7.1]
  def up
    # Enable pgvector extension
    enable_extension 'vector'

    # Add embedding column with vector type (1536 dimensions for OpenAI/DeepSeek)
    add_column :products, :embedding, :vector, limit: 1536
    add_column :products, :embedding_generated_at, :timestamptz

    # Add HNSW index for fast similarity search
    # Using cosine distance operator (<=>)
    add_index :products, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end

  def down
    remove_index :products, :embedding
    remove_column :products, :embedding_generated_at
    remove_column :products, :embedding
    disable_extension 'vector'
  end
end
