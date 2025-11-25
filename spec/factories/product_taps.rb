FactoryBot.define do
  factory :product_tap do
    association :product
    association :user, factory: :user, optional: true
    session_identifier { "session_#{SecureRandom.hex(16)}" }
  end
end
