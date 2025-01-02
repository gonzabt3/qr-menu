# app/models/restaurant.rb
class Restaurant < ApplicationRecord
  belongs_to :user
  has_many :menus, dependent: :destroy

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
