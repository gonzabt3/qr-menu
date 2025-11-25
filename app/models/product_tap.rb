# app/models/product_tap.rb
class ProductTap < ApplicationRecord
  belongs_to :product
  belongs_to :user, optional: true

  validates :product_id, presence: true
  validates :session_identifier, presence: true, unless: :user_id?

  # Scopes for analytics
  scope :recent, -> { order(created_at: :desc) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_session, ->(session_id) { where(session_identifier: session_id) }
  scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Analytics methods
  def self.count_by_product
    group(:product_id).count
  end

  def self.count_by_product_with_details
    joins(:product)
      .select('products.id, products.name, COUNT(product_taps.id) as tap_count')
      .group('products.id, products.name')
      .order('tap_count DESC')
  end
end
