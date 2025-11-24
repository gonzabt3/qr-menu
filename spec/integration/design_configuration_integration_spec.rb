# spec/integration/design_configuration_integration_spec.rb
require 'rails_helper'

RSpec.describe 'Design Configuration Integration', type: :request do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user, name: 'TestRestaurant') }
  let(:menu) { create(:menu, restaurant: restaurant) }
  
  before do
    # Mock Auth0 authentication
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
  end

  describe 'Complete design configuration workflow' do
    it 'creates, updates, and retrieves design configuration' do
      # 1. Initially no design configuration exists
      expect(menu.design_configuration).to be_nil

      # 2. GET design configuration creates default one
      get "/restaurants/#{restaurant.id}/menus/#{menu.id}/design_configuration"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['primaryColor']).to eq('#ff7a00')
      expect(json['showWhatsApp']).to be_truthy
      
      menu.reload
      expect(menu.design_configuration).to be_present

      # 3. UPDATE design configuration
      put "/restaurants/#{restaurant.id}/menus/#{menu.id}/design_configuration", params: {
        design: {
          primaryColor: '#123456',
          secondaryColor: '#abcdef',
          backgroundColor: '#ffffff',
          textColor: '#000000',
          font: 'Inter',
          showWhatsApp: false,
          showMaps: true
        }
      }

      expect(response).to have_http_status(:success)
      updated_json = JSON.parse(response.body)
      expect(updated_json['primaryColor']).to eq('#123456')
      expect(updated_json['showWhatsApp']).to be_falsey
      expect(updated_json['showMaps']).to be_truthy

      # 4. Verify changes persisted
      menu.design_configuration.reload
      expect(menu.design_configuration.primary_color).to eq('#123456')
      expect(menu.design_configuration.show_whatsapp).to be_falsey
      expect(menu.design_configuration.show_maps).to be_truthy
    end
  end

  describe 'Public menu endpoints include design configuration' do
    let!(:design_config) do
      config = create(:design_configuration,
        menu: menu, 
        primary_color: '#123456',
        secondary_color: '#abcdef',
        background_color: '#ffffff',
        text_color: '#000000',
        font: 'Inter',
        show_whatsapp: false,
        show_maps: true
      )
    end

    before do
      # Make user subscribed so menus are public
      user.update!(subscribed: true)
      menu.update!(favorite: true)
    end

    it 'includes design configuration in QR endpoint' do
      get "/menus/by_restaurant_id/#{restaurant.id}"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['design_configuration']).to be_present
      expect(json['design_configuration']['primaryColor']).to eq('#123456')
      expect(json['design_configuration']['showWhatsApp']).to be_falsey
      expect(json['design_configuration']['showMaps']).to be_truthy
    end

    it 'includes design configuration in name endpoint' do
      get "/menus/by_name/#{restaurant.name}"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['design_configuration']).to be_present
      expect(json['design_configuration']['primaryColor']).to eq('#123456')
    end

    it 'includes restaurant data for contact buttons' do
      restaurant.update!(
        phone: '+1234567890',
        instagram: 'testrestaurant',
        address: '123 Test St'
      )

      get "/menus/by_restaurant_id/#{restaurant.id}"
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['restaurant']).to be_present
      expect(json['restaurant']['phone']).to eq('+1234567890')
      expect(json['restaurant']['instagram']).to eq('testrestaurant')
      expect(json['restaurant']['address']).to eq('123 Test St')
    end
  end

  describe 'Authorization and security' do
    let(:other_user) { create(:user) }
    let(:other_restaurant) { create(:restaurant, user: other_user) }
    let(:other_menu) { create(:menu, restaurant: other_restaurant) }

    it 'prevents unauthorized access to design configuration' do
      get "/restaurants/#{other_restaurant.id}/menus/#{other_menu.id}/design_configuration"
      
      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents unauthorized updates to design configuration' do
      put "/restaurants/#{other_restaurant.id}/menus/#{other_menu.id}/design_configuration", params: {
        design: { primaryColor: '#hacker' }
      }
      
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'Validation and error handling' do
    it 'returns validation errors for invalid data' do
      put "/restaurants/#{restaurant.id}/menus/#{menu.id}/design_configuration", params: {
        design: {
          primaryColor: 'invalid-color',
          font: 'InvalidFont'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json).to have_key('errors')
      expect(json['errors']).to be_an(Array)
      expect(json['errors']).to include('Primary color debe ser un color hexadecimal válido (ej: #ff7a00)')
      expect(json['errors']).to include('Font debe ser una fuente válida')
    end

    it 'handles missing menu gracefully' do
      get "/restaurants/#{restaurant.id}/menus/99999/design_configuration"
      
      expect(response).to have_http_status(:not_found)
    end
  end
end