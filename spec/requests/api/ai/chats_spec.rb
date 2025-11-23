# spec/requests/api/ai/chats_spec.rb
require 'rails_helper'

RSpec.describe 'Api::Ai::ChatsController', type: :request do
  describe 'POST /api/ai/chat' do
    let(:valid_params) do
      {
        user_query: '¿qué puedo comer si soy vegano?'
      }
    end

    context 'when feature flag is disabled' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FEATURE_AI_CHAT_ENABLED').and_return('false')
      end

      it 'returns forbidden status' do
        post '/api/ai/chat', params: valid_params, as: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('AI chat feature is not enabled')
      end
    end

    context 'when feature flag is enabled' do
      let(:mock_embedding) { Array.new(1536) { rand } }
      let(:mock_answer) { 'Tenemos varias opciones veganas disponibles en el menú.' }

      # Create required associations
      let!(:user) { create(:user) }
      let!(:restaurant) { create(:restaurant, user: user) }
      let!(:menu) { create(:menu, restaurant: restaurant) }
      let!(:section) { create(:section, menu: menu) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FEATURE_AI_CHAT_ENABLED').and_return('true')
        allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('false')
        allow(ENV).to receive(:[]).with('AI_PROVIDER').and_return('deepseak')
        allow(ENV).to receive(:[]).with('DEEPSEAK_API_KEY').and_return('test_key')
        
        # Mock AiClient methods
        allow(AiClient).to receive(:embed).and_return(mock_embedding)
        allow(AiClient).to receive(:complete).and_return(mock_answer)
      end

      context 'with valid query' do
        let!(:product1) do
          create(:product, 
                 section: section,
                 name: 'Ensalada Verde', 
                 description: 'Ensalada fresca con vegetales',
                 price: 10.50,
                 is_vegan: true,
                 embedding: mock_embedding)
        end

        let!(:product2) do
          create(:product,
                 section: section,
                 name: 'Hamburguesa de Carne',
                 description: 'Hamburguesa con carne',
                 price: 15.00,
                 is_vegan: false,
                 embedding: mock_embedding)
        end

        it 'returns a successful response with answer and references' do
          post '/api/ai/chat', params: valid_params, as: :json

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['answer']).to eq(mock_answer)
          expect(json_response['references']).to be_an(Array)
          expect(json_response['references'].first).to have_key('product_id')
          expect(json_response['references'].first).to have_key('name')
          expect(json_response['references'].first).to have_key('price')
        end

        it 'calls AiClient.embed with the user query' do
          expect(AiClient).to receive(:embed).with(valid_params[:user_query])
          post '/api/ai/chat', params: valid_params, as: :json
        end

        it 'calls AiClient.complete with prompt' do
          expect(AiClient).to receive(:complete).with(kind_of(String))
          post '/api/ai/chat', params: valid_params, as: :json
        end
      end

      context 'with missing user_query' do
        it 'returns bad request error' do
          post '/api/ai/chat', params: {}, as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('user_query is required')
        end
      end

      context 'when AiClient raises an error' do
        before do
          allow(AiClient).to receive(:embed).and_raise(StandardError.new('API Error'))
        end

        it 'returns internal server error' do
          post '/api/ai/chat', params: valid_params, as: :json

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Internal server error')
        end
      end
    end
  end
end
