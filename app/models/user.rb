class User < ApplicationRecord
  has_many :restaurants, dependent: :destroy
  has_many :feedbacks, dependent: :destroy

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
