# spec/requests/metrics/product_taps_spec.rb
require 'rails_helper'

RSpec.describe 'Metrics::ProductTaps', type: :request do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:section) { create(:section, menu: menu) }
  let(:product) { create(:product, section: section) }

  describe 'POST /metrics/product-tap' do
    context 'with valid product_id and session_identifier' do
      let(:valid_params) do
        {
          product_id: product.id,
          session_identifier: 'test-session-123'
        }
      end

      it 'creates a new ProductTap' do
        expect {
          post '/metrics/product-tap', params: valid_params
        }.to change(ProductTap, :count).by(1)
      end

      it 'returns created status' do
        post '/metrics/product-tap', params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns the created tap data' do
        post '/metrics/product-tap', params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Product tap recorded successfully')
        expect(json_response['tap']['product_id']).to eq(product.id)
        expect(json_response['tap']['session_identifier']).to eq('test-session-123')
      end
    end

    context 'with authenticated user' do
      let(:valid_params) do
        {
          product_id: product.id,
          user_id: user.id
        }
      end

      it 'creates a tap with user_id' do
        post '/metrics/product-tap', params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['tap']['user_id']).to eq(user.id)
      end
    end

    context 'with invalid product_id' do
      let(:invalid_params) do
        {
          product_id: 99999,
          session_identifier: 'test-session-123'
        }
      end

      it 'returns not found status' do
        post '/metrics/product-tap', params: invalid_params
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error message' do
        post '/metrics/product-tap', params: invalid_params
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Product not found')
      end
    end

    context 'without product_id' do
      let(:invalid_params) do
        {
          session_identifier: 'test-session-123'
        }
      end

      it 'returns not found status' do
        post '/metrics/product-tap', params: invalid_params
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without session_identifier or user_id' do
      let(:invalid_params) do
        {
          product_id: product.id
        }
      end

      it 'returns unprocessable entity status' do
        post '/metrics/product-tap', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        post '/metrics/product-tap', params: invalid_params
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
      end
    end
  end

  describe 'GET /metrics/product-taps' do
    let!(:product_tap1) { create(:product_tap, product: product, session_identifier: 'session-1') }
    let!(:product_tap2) { create(:product_tap, product: product, session_identifier: 'session-2') }
    let!(:product_tap3) { create(:product_tap, product: product, user: user) }

    it 'returns success status' do
      get '/metrics/product-taps'
      expect(response).to have_http_status(:ok)
    end

    it 'returns metrics data structure' do
      get '/metrics/product-taps'
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('total_taps')
      expect(json_response).to have_key('taps_by_product')
      expect(json_response).to have_key('recent_taps')
      expect(json_response).to have_key('top_products')
    end

    it 'returns correct total_taps count' do
      get '/metrics/product-taps'
      json_response = JSON.parse(response.body)
      expect(json_response['total_taps']).to eq(3)
    end

    it 'returns taps grouped by product' do
      get '/metrics/product-taps'
      json_response = JSON.parse(response.body)
      
      taps_by_product = json_response['taps_by_product']
      expect(taps_by_product).to be_an(Array)
      expect(taps_by_product.first['product_id']).to eq(product.id)
      expect(taps_by_product.first['product_name']).to eq(product.name)
      expect(taps_by_product.first['count']).to eq(3)
    end

    it 'returns recent taps' do
      get '/metrics/product-taps'
      json_response = JSON.parse(response.body)
      
      recent_taps = json_response['recent_taps']
      expect(recent_taps).to be_an(Array)
      expect(recent_taps.length).to eq(3)
      expect(recent_taps.first).to have_key('product_id')
      expect(recent_taps.first).to have_key('product_name')
      expect(recent_taps.first).to have_key('created_at')
    end

    it 'returns top products' do
      get '/metrics/product-taps'
      json_response = JSON.parse(response.body)
      
      top_products = json_response['top_products']
      expect(top_products).to be_an(Array)
      expect(top_products.first).to have_key('product_id')
      expect(top_products.first).to have_key('product_name')
      expect(top_products.first).to have_key('tap_count')
    end

    context 'when there are no taps' do
      before do
        ProductTap.destroy_all
      end

      it 'returns empty metrics' do
        get '/metrics/product-taps'
        json_response = JSON.parse(response.body)
        
        expect(json_response['total_taps']).to eq(0)
        expect(json_response['taps_by_product']).to be_empty
        expect(json_response['recent_taps']).to be_empty
        expect(json_response['top_products']).to be_empty
      end
    end
  end
end
