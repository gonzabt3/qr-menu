# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :section
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  before_destroy :delete_image_on_s3, if: -> { image_url.present? }
  
  # Trigger embedding generation after product is created or updated
  after_commit :enqueue_embedding_generation, on: [:create, :update]
  
  # Scope to find products with embeddings
  scope :with_embeddings, -> { where.not(embedding: nil) }
  
  # Generate combined text for embedding from product attributes
  def combined_text_for_embedding
    parts = []
    parts << "Nombre: #{name}" if name.present?
    parts << "Descripción: #{description}" if description.present?
    
    # Add dietary information
    dietary_info = []
    dietary_info << "vegano" if is_vegan?
    dietary_info << "apto para celíacos" if is_celiac?
    parts << "Características: #{dietary_info.join(', ')}" if dietary_info.any?
    
    # Add price information
    parts << "Precio: $#{price}" if price.present?
    
    parts.join(". ")
  end
  
  # Check if embedding needs regeneration
  def needs_embedding_regeneration?
    embedding.nil? || 
      embedding_generated_at.nil? || 
      updated_at > embedding_generated_at
  end
  
  private
  
  def enqueue_embedding_generation
    # Only enqueue if relevant fields have changed
    return unless saved_change_to_name? || 
                  saved_change_to_description? || 
                  saved_change_to_is_vegan? || 
                  saved_change_to_is_celiac? ||
                  saved_change_to_price? ||
                  needs_embedding_regeneration?
    
    ProductEmbeddingJob.perform_later(id)
  end
  
  def delete_image_on_s3
    client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    extension = image_url.split('.').last
    s3_path = "menus/#{section.menu.id}/products/#{id}.#{extension}"

    client.delete_object({
                           bucket: ENV['S3_BUCKET_NAME'],
                           key: s3_path
                         })
  end

end
