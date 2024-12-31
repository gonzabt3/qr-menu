# app/models/section.rb
class Section < ApplicationRecord
  belongs_to :menu
  has_many :products, dependent: :destroy

  validates :name, presence: true
end
