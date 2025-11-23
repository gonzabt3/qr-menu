require 'rails_helper'

RSpec.describe 'Api::Ai::ChatsController', type: :request do
  describe 'POST /api/ai/chat' do
    let(:user_query) { '¿qué puedo comer si soy vegano?' }
    let(:valid_params) do
      {
        user_query: user_query,
        locale: 'es'
      }
    end

    context 'when feature flag is disabled' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FEATURE_AI_CHAT_ENABLED').and_return('false')
      end

      it 'returns 404 not found' do
        post '/api/ai/chat', params: valid_params, as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('AI chat feature is not enabled')
      end
    end

    context 'when feature flag is enabled' do
      let!(:restaurant) { create(:restaurant) }
      let!(:menu) { create(:menu, restaurant: restaurant) }
      let!(:section) { create(:section, menu: menu) }
      let!(:vegan_product) do
        create(:product,
               section: section,
               name: 'Ensalada Vegana',
               description: 'Ensalada fresca con vegetales',
               price: 10.0,
               is_vegan: true,
               embedding: "[#{([0.1] * 1536).join(',')}]")
      end
      let!(:regular_product) do
        create(:product,
               section: section,
               name: 'Hamburguesa',
               description: 'Hamburguesa con carne',
               price: 15.0,
               is_vegan: false,
               embedding: "[#{([0.5] * 1536).join(',')}]")
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FEATURE_AI_CHAT_ENABLED').and_return('true')
        allow(ENV).to receive(:[]).with('AI_PROVIDER').and_return('openai')
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
        allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('false')
      end

      context 'with valid user query' do
        let(:mock_embedding) { [0.1] * 1536 }
        let(:mock_answer) { 'Te recomiendo la Ensalada Vegana, que es completamente vegana y fresca.' }

        before do
          # Mock AiClient.embed
          allow(AiClient).to receive(:embed).with(user_query).and_return(mock_embedding)
          
          # Mock AiClient.complete
          allow(AiClient).to receive(:complete).and_return(mock_answer)
        end

        it 'returns a successful response with answer and references' do
          post '/api/ai/chat', params: valid_params, as: :json

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['answer']).to eq(mock_answer)
          expect(json_response['references']).to be_an(Array)
          expect(json_response['references'].length).to be > 0
          expect(json_response['session_id']).to be_present
        end

        it 'includes product references in response' do
          post '/api/ai/chat', params: valid_params, as: :json

          json_response = JSON.parse(response.body)
          references = json_response['references']
          
          expect(references.first).to have_key('product_id')
          expect(references.first).to have_key('name')
          expect(references.first).to have_key('score')
        end

        it 'calls AiClient.embed with user query' do
          expect(AiClient).to receive(:embed).with(user_query).and_return(mock_embedding)
          
          post '/api/ai/chat', params: valid_params, as: :json
        end

        it 'calls AiClient.complete with prompt' do
          expect(AiClient).to receive(:complete).with(
            kind_of(Array),
            hash_including(temperature: 0.7, max_tokens: 500)
          ).and_return(mock_answer)
          
          post '/api/ai/chat', params: valid_params, as: :json
        end
      end

      context 'with missing user_query parameter' do
        it 'returns bad request error' do
          post '/api/ai/chat', params: { locale: 'es' }, as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('user_query is required')
        end
      end

      context 'with empty user_query' do
        it 'returns bad request error' do
          post '/api/ai/chat', params: { user_query: '', locale: 'es' }, as: :json

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('user_query is required')
        end
      end

      context 'when AiClient raises an error' do
        before do
          allow(AiClient).to receive(:embed).and_raise(StandardError.new('API error'))
        end

        it 'returns internal server error' do
          post '/api/ai/chat', params: valid_params, as: :json

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('An error occurred while processing your request')
        end
      end

      context 'with custom session_id' do
        let(:custom_session_id) { 'custom-session-123' }

        before do
          allow(AiClient).to receive(:embed).and_return([0.1] * 1536)
          allow(AiClient).to receive(:complete).and_return('Test answer')
        end

        it 'uses the provided session_id' do
          post '/api/ai/chat', params: valid_params.merge(session_id: custom_session_id), as: :json

          json_response = JSON.parse(response.body)
          expect(json_response['session_id']).to eq(custom_session_id)
        end
      end
    end
  end
end
