# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :section
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  before_destroy :delete_image_on_s3, if: -> { image_url.present? }
  
  
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
