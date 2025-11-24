# spec/models/design_configuration_spec.rb
require 'rails_helper'

RSpec.describe DesignConfiguration, type: :model do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }

  describe 'associations' do
    it { should belong_to(:menu) }
  end

  describe 'validations' do
    subject { build(:design_configuration, menu: menu) }

    it { should validate_presence_of(:primary_color) }
    it { should validate_presence_of(:secondary_color) }
    it { should validate_presence_of(:background_color) }
    it { should validate_presence_of(:text_color) }
    it { should validate_presence_of(:font) }

    describe 'color format validation' do
      it 'accepts valid hex colors' do
        config = build(:design_configuration, menu: menu, primary_color: '#ff7a00')
        expect(config).to be_valid
      end

      it 'rejects invalid hex colors' do
        config = build(:design_configuration, menu: menu, primary_color: 'invalid')
        expect(config).not_to be_valid
        expect(config.errors[:primary_color]).to include('debe ser un color hexadecimal válido (ej: #ff7a00)')
      end

      it 'rejects hex colors without #' do
        config = build(:design_configuration, menu: menu, primary_color: 'ff7a00')
        expect(config).not_to be_valid
      end

      it 'rejects short hex colors' do
        config = build(:design_configuration, menu: menu, primary_color: '#fff')
        expect(config).not_to be_valid
      end
    end

    describe 'font validation' do
      it 'accepts valid fonts' do
        valid_fonts = ['Inter', 'Roboto', 'Playfair Display', 'Montserrat', 'Poppins', 'Open Sans', 'Lato']
        valid_fonts.each do |font|
          config = build(:design_configuration, menu: menu, font: font)
          expect(config).to be_valid
        end
      end

      it 'rejects invalid fonts' do
        config = build(:design_configuration, menu: menu, font: 'InvalidFont')
        expect(config).not_to be_valid
        expect(config.errors[:font]).to include('debe ser una fuente válida')
      end
    end
  end

  describe '.default_config' do
    it 'returns expected default configuration' do
      default = DesignConfiguration.default_config
      
      expect(default).to include(
        primary_color: '#ff7a00',
        secondary_color: '#64748b',
        background_color: '#fefaf4',
        text_color: '#1f2937',
        font: 'Inter',
        logo_url: '',
        show_whatsapp: true,
        show_instagram: true,
        show_phone: true,
        show_maps: false,
        show_restaurant_logo: true
      )
    end
  end

  describe '#to_design_hash' do
    it 'converts to frontend format correctly' do
      config = create(:design_configuration, 
        menu: menu,
        primary_color: '#ff7a00',
        secondary_color: '#64748b',
        show_whatsapp: true,
        show_maps: false
      )

      hash = config.to_design_hash

      expect(hash).to include(
        primaryColor: '#ff7a00',
        secondaryColor: '#64748b',
        showWhatsApp: true,
        showMaps: false
      )
    end
  end

  describe '#update_from_design_hash' do
    let(:design_config) { create(:design_configuration, menu: menu) }
    
    it 'updates from frontend hash with symbol keys' do
      hash = {
        primaryColor: '#123456',
        secondaryColor: '#abcdef',
        backgroundColor: '#ffffff',
        textColor: '#000000',
        font: 'Inter',
        showWhatsApp: false,
        showMaps: true
      }

      design_config.update_from_design_hash(hash)
      design_config.reload

      expect(design_config.primary_color).to eq('#123456')
      expect(design_config.secondary_color).to eq('#abcdef')
      expect(design_config.background_color).to eq('#ffffff')
      expect(design_config.text_color).to eq('#000000')
      expect(design_config.font).to eq('Inter')
      expect(design_config.show_whatsapp).to be_falsey
      expect(design_config.show_maps).to be_truthy
    end

    it 'updates from frontend hash with string keys' do
      hash = {
        'primaryColor' => '#654321',
        'secondaryColor' => '#fedcba',
        'backgroundColor' => '#f0f0f0',
        'textColor' => '#333333',
        'font' => 'Roboto',
        'showInstagram' => false
      }

      design_config.update_from_design_hash(hash)
      design_config.reload

      expect(design_config.primary_color).to eq('#654321')
      expect(design_config.secondary_color).to eq('#fedcba')
      expect(design_config.background_color).to eq('#f0f0f0')
      expect(design_config.text_color).to eq('#333333')
      expect(design_config.font).to eq('Roboto')
      expect(design_config.show_instagram).to be_falsey
    end
  end
end