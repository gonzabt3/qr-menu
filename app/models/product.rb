# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :section

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
