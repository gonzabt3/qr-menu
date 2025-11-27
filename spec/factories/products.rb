FactoryBot.define do
  factory :product do
    name { "Pizza Margherita" }
    description { "Pizza tradicional con mozzarella y albahaca" }
    price { 9.99 }
    is_vegan { false }
    is_celiac { false }
    association :section
  end
end
