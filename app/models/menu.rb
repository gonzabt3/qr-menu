class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :sections, dependent: :destroy

  validates :name, presence: true
end
