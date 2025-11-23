class AddEmbeddingToProducts < ActiveRecord::Migration[7.1]
  def up
    # Enable pgvector extension
    enable_extension 'vector'

    # Add embedding column with vector type (1536 dimensions for OpenAI/DeepSeek)
    # Using execute to explicitly specify dimensions
    execute 'ALTER TABLE products ADD COLUMN embedding vector(1536);'
    add_column :products, :embedding_generated_at, :timestamptz

    # Add index for fast similarity search using ivfflat
    # ivfflat is good for approximate nearest neighbor search
    execute <<-SQL
      CREATE INDEX index_products_on_embedding_ivfflat 
      ON products 
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    execute 'DROP INDEX IF EXISTS index_products_on_embedding_ivfflat;'
    remove_column :products, :embedding_generated_at
    execute 'ALTER TABLE products DROP COLUMN IF EXISTS embedding;'
    disable_extension 'vector'
  end
end
