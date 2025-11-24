# spec/controllers/design_configurations_controller_spec.rb
require 'rails_helper'

RSpec.describe DesignConfigurationsController, type: :controller do
  let(:user) { create(:user, email: 'test@example.com') }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
  end

  describe 'GET #show' do
    context 'when design_configuration exists' do
      let!(:design_config) { create(:design_configuration, menu: menu, primary_color: '#123456') }

      it 'returns the design configuration' do
        get :show, params: { restaurant_id: restaurant.id, menu_id: menu.id }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['primaryColor']).to eq('#123456')
      end
    end

    context 'when design_configuration does not exist' do
      it 'creates and returns default design configuration' do
        expect(menu.design_configuration).to be_nil
        
        get :show, params: { restaurant_id: restaurant.id, menu_id: menu.id }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['primaryColor']).to eq('#ff7a00')
        
        menu.reload
        expect(menu.design_configuration).to be_present
      end
    end
  end

  describe 'PUT #update' do
    let!(:design_config) { create(:design_configuration, menu: menu) }
    
    let(:valid_params) do
      {
        restaurant_id: restaurant.id,
        menu_id: menu.id,
        design: {
          primaryColor: '#654321',
          secondaryColor: '#abcdef',
          showWhatsApp: false,
          showMaps: true
        }
      }
    end

    it 'updates design configuration successfully' do
      put :update, params: valid_params
      
      expect(response).to have_http_status(:success)
      
      design_config.reload
      expect(design_config.primary_color).to eq('#654321')
      expect(design_config.secondary_color).to eq('#abcdef')
      expect(design_config.show_whatsapp).to be_falsey
      expect(design_config.show_maps).to be_truthy
    end

    it 'returns updated configuration in response' do
      put :update, params: valid_params
      
      json = JSON.parse(response.body)
      expect(json['primaryColor']).to eq('#654321')
      expect(json['showWhatsApp']).to be_falsey
    end

    context 'with invalid data' do
      let(:invalid_params) do
        {
          restaurant_id: restaurant.id,
          menu_id: menu.id,
          design: {
            primaryColor: 'invalid-color',
            font: 'InvalidFont'
          }
        }
      end

      it 'returns validation errors' do
        put :update, params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to have_key('errors')
        expect(json['errors']).to be_an(Array)
        expect(json['errors']).to include('Primary color debe ser un color hexadecimal válido (ej: #ff7a00)')
      end
    end
  end

  describe 'authorization' do
    let(:other_user) { create(:user, email: 'other@example.com') }
    let(:other_restaurant) { create(:restaurant, user: other_user) }
    let(:other_menu) { create(:menu, restaurant: other_restaurant) }

    it 'prevents access to other users restaurants' do
      get :show, params: { restaurant_id: other_restaurant.id, menu_id: other_menu.id }
      
      expect(response).to have_http_status(:forbidden)
    end
  end
end