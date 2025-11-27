FactoryBot.define do
  factory :section do
    name { "Pizzas" }
    description { "Nuestras deliciosas pizzas" }
    association :menu
  end
end
