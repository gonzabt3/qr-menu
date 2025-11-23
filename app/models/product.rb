# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :section
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  before_destroy :delete_image_on_s3, if: -> { image_url.present? }
  
  # Enqueue embedding job when product is created or updated, if AI chat feature is enabled
  after_commit :enqueue_embedding_job, on: [:create, :update], if: :should_generate_embedding?
  
  # Combine all product text fields for embedding generation
  def combined_text_for_embedding
    parts = []
    parts << "Nombre: #{name}" if name.present?
    parts << "Descripción: #{description}" if description.present?
    parts << "Precio: $#{price}" if price.present?
    
    # Add dietary information
    dietary_tags = []
    dietary_tags << "vegano" if is_vegan
    dietary_tags << "celíaco" if is_celiac
    parts << "Apto para: #{dietary_tags.join(', ')}" if dietary_tags.any?
    
    parts.join(". ")
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

  private

  def should_generate_embedding?
    ENV['FEATURE_AI_CHAT_ENABLED'] == 'true'
  end

  def enqueue_embedding_job
    ProductEmbeddingJob.perform_async(id)
  end
end
