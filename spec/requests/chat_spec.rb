require 'rails_helper'

RSpec.describe ChatController, type: :request do
  let(:restaurant) { create(:restaurant) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:section) { create(:section, menu: menu) }
  let!(:product1) do
    create(:product, 
      section: section,
      name: 'Ensalada Vegana',
      description: 'Ensalada fresca con vegetales orgánicos',
      price: 12.50,
      is_vegan: true,
      is_celiac: true
    )
  end
  let!(:product2) do
    create(:product,
      section: section,
      name: 'Pizza Margherita',
      description: 'Pizza tradicional con mozzarella',
      price: 15.00,
      is_vegan: false
    )
  end
  
  let(:mock_ai_client) { instance_double(AiClient::Deepseek) }
  let(:query_embedding) { Array.new(1536) { rand(-1.0..1.0) } }
  let(:ai_response) { 'Tenemos una deliciosa Ensalada Vegana que es perfecta para ti.' }

  before do
    allow(AiClient).to receive(:instance).and_return(mock_ai_client)
    
    # Set up embeddings for products
    product1.update_columns(embedding: Array.new(1536) { rand(-1.0..1.0) })
    product2.update_columns(embedding: Array.new(1536) { rand(-1.0..1.0) })
  end

  describe 'POST /chat' do
    context 'with valid request' do
      before do
        allow(mock_ai_client).to receive(:embed).and_return(query_embedding)
        allow(mock_ai_client).to receive(:complete).and_return(ai_response)
      end

      it 'returns successful response with answer and references' do
        post '/chat', params: {
          user_query: '¿Tienen opciones veganas?',
          menu_id: menu.id
        }, as: :json

        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['answer']).to eq(ai_response)
        expect(json['references']).to be_an(Array)
      end

      it 'includes product references with details' do
        post '/chat', params: {
          user_query: '¿Tienen opciones veganas?',
          menu_id: menu.id
        }, as: :json

        json = JSON.parse(response.body)
        reference = json['references'].first
        
        expect(reference).to include(
          'product_id',
          'name',
          'description',
          'price',
          'similarity_score',
          'is_vegan',
          'is_celiac'
        )
      end

      it 'generates embedding for user query' do
        expect(mock_ai_client).to receive(:embed)
          .with('¿Tienen opciones veganas?')
          .and_return(query_embedding)

        post '/chat', params: {
          user_query: '¿Tienen opciones veganas?',
          menu_id: menu.id
        }, as: :json
      end

      it 'calls AI completion with RAG prompt' do
        expect(mock_ai_client).to receive(:complete) do |prompt, options|
          expect(prompt).to include('Productos relevantes')
          expect(prompt).to include('Pregunta del cliente')
          expect(options[:temperature]).to eq(0.7)
          expect(options[:max_tokens]).to eq(500)
          ai_response
        end

        post '/chat', params: {
          user_query: '¿Tienen opciones veganas?',
          menu_id: menu.id
        }, as: :json
      end

      it 'respects top_k parameter' do
        post '/chat', params: {
          user_query: 'comida',
          menu_id: menu.id,
          top_k: 1
        }, as: :json

        json = JSON.parse(response.body)
        expect(json['references'].length).to be <= 1
      end

      it 'defaults to Spanish locale' do
        post '/chat', params: {
          user_query: '¿Qué recomiendas?',
          menu_id: menu.id
        }, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with missing user_query' do
      it 'returns bad request error' do
        post '/chat', params: {
          menu_id: menu.id
        }, as: :json

        expect(response).to have_http_status(:bad_request)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('user_query is required')
      end
    end

    context 'with missing menu_id' do
      it 'returns bad request error' do
        post '/chat', params: {
          user_query: 'test query'
        }, as: :json

        expect(response).to have_http_status(:bad_request)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('menu_id is required')
      end
    end

    context 'with non-existent menu' do
      it 'returns not found error' do
        post '/chat', params: {
          user_query: 'test query',
          menu_id: 99999
        }, as: :json

        expect(response).to have_http_status(:not_found)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('Menu not found')
      end
    end

    context 'with no matching products' do
      before do
        allow(mock_ai_client).to receive(:embed).and_return(query_embedding)
        # Clear embeddings so no products match
        Product.update_all(embedding: nil)
      end

      it 'returns helpful message' do
        post '/chat', params: {
          user_query: 'something unrelated',
          menu_id: menu.id
        }, as: :json

        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['answer']).to include('no encontré productos')
        expect(json['references']).to be_empty
      end
    end

    context 'with AI configuration error' do
      before do
        allow(AiClient).to receive(:instance)
          .and_raise(AiClient::ConfigurationError, 'API key not set')
      end

      it 'returns service unavailable error' do
        post '/chat', params: {
          user_query: 'test query',
          menu_id: menu.id
        }, as: :json

        expect(response).to have_http_status(:service_unavailable)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('not properly configured')
      end
    end

    context 'with AI API error' do
      before do
        allow(mock_ai_client).to receive(:embed)
          .and_raise(AiClient::ApiError, 'API temporarily unavailable')
      end

      it 'returns service unavailable error' do
        post '/chat', params: {
          user_query: 'test query',
          menu_id: menu.id
        }, as: :json

        expect(response).to have_http_status(:service_unavailable)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('temporarily unavailable')
      end
    end

    context 'with unexpected error' do
      before do
        allow(mock_ai_client).to receive(:embed)
          .and_raise(StandardError, 'Unexpected error')
      end

      it 'returns internal server error' do
        post '/chat', params: {
          user_query: 'test query',
          menu_id: menu.id
        }, as: :json

        expect(response).to have_http_status(:internal_server_error)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('unexpected error')
      end
    end
  end
end
