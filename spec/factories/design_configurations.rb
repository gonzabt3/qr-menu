# spec/factories/design_configurations.rb
FactoryBot.define do
  factory :design_configuration do
    association :menu
    primary_color { '#ff7a00' }
    secondary_color { '#64748b' }
    background_color { '#fefaf4' }
    text_color { '#1f2937' }
    font { 'Inter' }
    logo_url { '' }
    show_whatsapp { true }
    show_instagram { true }
    show_phone { true }
    show_maps { false }
    show_restaurant_logo { true }

    trait :with_custom_colors do
      primary_color { '#123456' }
      secondary_color { '#654321' }
      background_color { '#ffffff' }
      text_color { '#000000' }
    end

    trait :with_all_contacts_disabled do
      show_whatsapp { false }
      show_instagram { false }
      show_phone { false }
      show_maps { false }
      show_restaurant_logo { false }
    end

    trait :with_playfair_font do
      font { 'Playfair Display' }
    end
  end
end