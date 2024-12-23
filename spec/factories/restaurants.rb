# spec/factories/restaurants.rb
FactoryBot.define do
  factory :restaurant do
    name { "Test Restaurant" }
    address { "123 Test St" }
    phone { "123-456-7890" }
    email { "test@example.com" }
    website { "http://example.com" }
    instagram { "http://instagram.com/test" }
    description { "A test restaurant" }
    association :user
  end
end