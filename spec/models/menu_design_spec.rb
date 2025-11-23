# spec/models/menu_spec.rb (agregando tests para design_configuration)
require 'rails_helper'

RSpec.describe Menu, type: :model do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }

  describe 'associations' do
    it { should belong_to(:restaurant) }
    it { should have_many(:sections).dependent(:destroy) }
    it { should have_one(:design_configuration).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe '#get_design_configuration' do
    context 'when design_configuration exists' do
      let!(:design_config) { create(:design_configuration, menu: menu) }

      it 'returns existing design_configuration' do
        expect(menu.get_design_configuration).to eq(design_config)
      end
    end

    context 'when design_configuration does not exist' do
      it 'creates and returns new design_configuration with defaults' do
        expect(menu.design_configuration).to be_nil
        
        result = menu.get_design_configuration
        
        expect(result).to be_persisted
        expect(result.primary_color).to eq('#ff7a00')
        expect(result.show_whatsapp).to be_truthy
        expect(menu.design_configuration).to eq(result)
      end
    end
  end

  describe '#design_config_hash' do
    let!(:design_config) { create(:design_configuration, menu: menu, primary_color: '#123456') }

    it 'returns design configuration as hash' do
      hash = menu.design_config_hash
      
      expect(hash).to include(primaryColor: '#123456')
      expect(hash).to be_a(Hash)
    end
  end
end