FactoryBot.define do
  factory :menu do
    name { "Menú Principal" }
    description { "Nuestro menú completo" }
    association :restaurant
  end
end
