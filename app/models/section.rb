# app/models/section.rb
class Section < ApplicationRecord
  belongs_to :menu
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :order, presence: true, numericality: { only_integer: true }

  default_scope { order(:order) }
end
