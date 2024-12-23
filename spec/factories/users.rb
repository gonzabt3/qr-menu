# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { "test@example.com" }
    auth0_id { "auth0|123456" }
  end
end