# frozen_string_literal: true

# Background job to generate embeddings for products
class ProductEmbeddingJob
  include Sidekiq::Job
  
  sidekiq_options queue: :embeddings, retry: 3

  # Generate embedding for a product
  # @param product_id [Integer] ID of the product
  def perform(product_id)
    product = Product.find_by(id: product_id)
    
    unless product
      log_error("Product #{product_id} not found")
      return
    end

    log_info("Generating embedding for product #{product_id} (#{product.name})")
    
    # Get text to embed
    text = product.combined_text_for_embedding
    
    if text.blank?
      log_info("Product #{product_id} has no text to embed, skipping")
      return
    end
    
    # Generate embedding
    embedding = AiClient.embed(text)
    
    # Save embedding to product
    # Convert array to pgvector format (string representation)
    embedding_str = "[#{embedding.join(',')}]"
    product.update_columns(
      embedding: embedding_str,
      embedding_generated_at: Time.current
    )
    
    log_info("Successfully saved embedding for product #{product_id}")
  rescue StandardError => e
    log_error("Error generating embedding for product #{product_id}: #{e.message}")
    log_error(e.backtrace.join("\n")) if logging_enabled?
    raise # Re-raise to trigger Sidekiq retry
  end

  private

  def log_info(message)
    return unless logging_enabled?
    Rails.logger.info("[ProductEmbeddingJob] #{message}")
  end

  def log_error(message)
    return unless logging_enabled?
    Rails.logger.error("[ProductEmbeddingJob] #{message}")
  end

  def logging_enabled?
    ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
  end
end
