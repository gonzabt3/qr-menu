FactoryBot.define do
  factory :product_tap do
    association :product
    user { nil }
    session_identifier { "session_#{SecureRandom.hex(16)}" }
  end
end
