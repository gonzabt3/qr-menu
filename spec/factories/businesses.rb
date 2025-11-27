FactoryBot.define do
  factory :business do
    sequence(:place_id) { |n| "place_#{n}" }
    name { Faker::Restaurant.name }
    address { Faker::Address.full_address }
    lat { Faker::Address.latitude }
    lng { Faker::Address.longitude }
    phone { Faker::PhoneNumber.phone_number }
    website { Faker::Internet.url }
    google_place_url { Faker::Internet.url }
    instagram { nil }
    has_menu { false }
    menu_urls { [] }
    raw_response { {} }
    status { "new" }
  end
end
