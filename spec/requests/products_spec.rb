# spec/requests/products_controller_spec.rb
require 'rails_helper'

RSpec.describe 'Products', type: :request do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:section) { create(:section, menu: menu) }
  let(:product) { create(:product, section: section) }
  let(:valid_attributes) do
    {
      name: 'Test Product',
      description: 'A test product',
      price: 9.99
    }
  end
  let(:invalid_attributes) do
    { name: nil }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'GET /restaurants/:restaurant_id/menus/:menu_id/products' do
    it 'returns a success response' do
      get restaurant_menu_products_path(restaurant, menu)
      expect(response).to be_successful
    end
  end

  describe 'GET /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products' do
    it 'returns a success response' do
      get restaurant_menu_section_products_path(restaurant, menu, section)
      expect(response).to be_successful
    end
  end

  describe 'GET /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id' do
    it 'returns a success response' do
      get restaurant_menu_section_product_path(restaurant, menu, section, product)
      expect(response).to be_successful
    end
  end

  describe 'POST /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products' do
    context 'with valid params' do
      it 'creates a new Product' do
        expect do
          post restaurant_menu_section_products_path(restaurant, menu, section), params: { product: valid_attributes }
        end.to change(Product, :count).by(1)
      end

      it 'renders a JSON response with the new product' do
        post restaurant_menu_section_products_path(restaurant, menu, section), params: { product: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new product' do
        post restaurant_menu_section_products_path(restaurant, menu, section), params: { product: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'PUT /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Product' }
      end

      it 'updates the requested product' do
        put restaurant_menu_section_product_path(restaurant, menu, section, product),
            params: { product: new_attributes }
        product.reload
        expect(product.name).to eq('Updated Product')
      end

      it 'renders a JSON response with the product' do
        put restaurant_menu_section_product_path(restaurant, menu, section, product),
            params: { product: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the product' do
        put restaurant_menu_section_product_path(restaurant, menu, section, product),
            params: { product: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'DELETE /restaurants/:restaurant_id/menus/:menu_id/sections/:section_id/products/:id' do
    it 'destroys the requested product' do
      product
      expect do
        delete restaurant_menu_section_product_path(restaurant, menu, section, product)
      end.to change(Product, :count).by(-1)
    end
  end
end
