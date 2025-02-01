require 'rails_helper'

RSpec.describe 'Menus', type: :request do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:valid_attributes) do
    {
      name: 'Test Menu',
      description: 'A test menu'
    }
  end
  let(:invalid_attributes) do
    { name: nil }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'GET /menus/by_name/:name' do
    let!(:restaurant1) { create(:restaurant, name: 'test resto', user: user) }
    let!(:menu1) { create(:menu, name: 'Test Menu', restaurant: restaurant1) }
    it 'returns a success response' do
      get menus_by_name_path(name: 'test resto')
      expect(response).to be_successful
      expect(JSON.parse(response.body)['name']).to eq('Test Menu')
    end

    it 'returns a not found response if menu does not exist' do
      get menus_by_name_path(name: 'Nonexistent Menu')
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /restaurants/:restaurant_id/menus' do
    it 'returns a success response' do
      get restaurant_menus_path(restaurant)
      expect(response).to be_successful
    end
  end

  describe 'GET /restaurants/:restaurant_id/menus/:id' do
    it 'returns a success response' do
      get restaurant_menu_path(restaurant, menu)
      expect(response).to be_successful
    end
  end

  describe 'POST /restaurants/:restaurant_id/menus' do
    context 'with valid params' do
      it 'creates a new Menu' do
        expect do
          post restaurant_menus_path(restaurant), params: { menu: valid_attributes }
        end.to change(Menu, :count).by(1)
      end

      it 'renders a JSON response with the new menu' do
        post restaurant_menus_path(restaurant), params: { menu: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new menu' do
        post restaurant_menus_path(restaurant), params: { menu: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'PUT /restaurants/:restaurant_id/menus/:id' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Menu' }
      end

      it 'updates the requested menu' do
        put restaurant_menu_path(restaurant, menu), params: { menu: new_attributes }
        menu.reload
        expect(menu.name).to eq('Updated Menu')
      end

      it 'renders a JSON response with the menu' do
        put restaurant_menu_path(restaurant, menu), params: { menu: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the menu' do
        put restaurant_menu_path(restaurant, menu), params: { menu: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'DELETE /restaurants/:restaurant_id/menus/:id' do
    it 'destroys the requested menu' do
      menu
      expect do
        delete restaurant_menu_path(restaurant, menu)
      end.to change(Menu, :count).by(-1)
    end
  end

  describe 'PUT #set_favorite' do
    let(:menu1) { create(:menu, restaurant: restaurant) }
    let(:menu2) { create(:menu, restaurant: restaurant) }

    context 'when the user is the owner of the restaurant' do
      it 'sets the selected menu as favorite and others as not favorite' do
        put set_favorite_restaurant_menu_path(restaurant, menu1)
        menu1.reload
        menu2.reload

        expect(menu1.favorite).to be true
        expect(menu2.favorite).to be false
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the restaurant does not exist' do
      it 'returns a not found status' do
        put set_favorite_restaurant_menu_path(2, menu1)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the menu does not exist' do
      it 'returns a not found status' do
        put set_favorite_restaurant_menu_path(restaurant, 3)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
