# app/jobs/product_embedding_job.rb
# Background job to generate and store embeddings for products
class ProductEmbeddingJob < ApplicationJob
  queue_as :default

  retry_on AiClient::ApiError, wait: :exponentially_longer, attempts: 3
  discard_on AiClient::ConfigurationError

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return unless product

    # Skip if embedding is already up to date
    return unless product.needs_embedding_regeneration?

    # Generate combined text for embedding
    text = product.combined_text_for_embedding
    
    # Generate embedding using configured AI provider
    ai_client = AiClient.instance
    embedding = ai_client.embed(text)

    # Store the embedding
    product.update_columns(
      embedding: embedding,
      embedding_generated_at: Time.current
    )

    Rails.logger.info("Generated embedding for product #{product_id}: #{product.name}")
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("Product #{product_id} not found for embedding generation: #{e.message}")
  rescue AiClient::Error => e
    Rails.logger.error("AI client error for product #{product_id}: #{e.message}")
    raise # Will trigger retry
  rescue StandardError => e
    Rails.logger.error("Unexpected error generating embedding for product #{product_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
