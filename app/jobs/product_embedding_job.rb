# app/jobs/product_embedding_job.rb
class ProductEmbeddingJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  def perform(product_id)
    product = Product.find_by(id: product_id)
    
    unless product
      log_info("Product #{product_id} not found, skipping")
      return
    end

    log_info("Generating embedding for product #{product_id}: #{product.name}")
    
    # Compose text for embedding
    text = product.combined_text_for_embedding
    
    if text.blank?
      log_info("No text available for product #{product_id}, skipping")
      return
    end

    # Generate embedding using AI service
    start_time = Time.current
    embedding = AiClient.embed(text)
    duration = Time.current - start_time

    # Save embedding to database
    # Use Pgvector.encode to convert array to pgvector format
    product.update_columns(
      embedding: Pgvector.encode(embedding),
      embedding_generated_at: Time.current
    )

    log_info("Successfully generated embedding for product #{product_id} in #{duration.round(2)}s")
  rescue StandardError => e
    log_error("Failed to generate embedding for product #{product_id}: #{e.message}")
    log_error(e.backtrace.join("\n"))
    raise # Let Sidekiq handle retry logic
  end

  private

  def log_info(message)
    Rails.logger.info("[ProductEmbeddingJob] #{message}") if logging_enabled?
  end

  def log_error(message)
    Rails.logger.error("[ProductEmbeddingJob] #{message}") if logging_enabled?
  end

  def logging_enabled?
    ENV['ENABLE_AI_CHAT_LOGS'] == 'true'
  end
end
