class Feedback < ApplicationRecord
  validates :message, presence: true, length: { maximum: 2000 }
end
