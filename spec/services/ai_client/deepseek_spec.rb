require 'rails_helper'

RSpec.describe AiClient::Deepseek, type: :service do
  let(:api_key) { 'test-deepseek-key' }
  
  before do
    allow(ENV).to receive(:[]).with('DEEPSEEK_API_KEY').and_return(api_key)
  end

  describe '#initialize' do
    context 'with valid API key' do
      it 'initializes successfully' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'without API key' do
      before do
        allow(ENV).to receive(:[]).with('DEEPSEEK_API_KEY').and_return(nil)
      end

      it 'raises ConfigurationError' do
        expect {
          described_class.new
        }.to raise_error(AiClient::ConfigurationError, /DEEPSEEK_API_KEY/)
      end
    end
  end

  describe '#embed' do
    let(:client) { described_class.new }
    let(:text) { 'Test product description' }

    context 'with valid text' do
      it 'returns array of 1536 floats' do
        embedding = client.embed(text)
        
        expect(embedding).to be_an(Array)
        expect(embedding.length).to eq(1536)
        expect(embedding.all? { |v| v.is_a?(Float) }).to be true
      end

      it 'generates deterministic embeddings for same text' do
        embedding1 = client.embed(text)
        embedding2 = client.embed(text)
        
        expect(embedding1).to eq(embedding2)
      end

      it 'generates different embeddings for different text' do
        embedding1 = client.embed('Pizza Margherita')
        embedding2 = client.embed('Hamburguesa con queso')
        
        expect(embedding1).not_to eq(embedding2)
      end

      it 'normalizes the embedding vector' do
        embedding = client.embed(text)
        magnitude = Math.sqrt(embedding.sum { |x| x * x })
        
        expect(magnitude).to be_within(0.01).of(1.0)
      end
    end

    context 'with blank text' do
      it 'returns zero vector' do
        embedding = client.embed('')
        
        expect(embedding).to eq(Array.new(1536, 0.0))
      end
    end
  end

  describe '#complete' do
    let(:client) { described_class.new }
    let(:prompt) { 'What vegan options do you have?' }
    
    before do
      # Mock HTTParty response
      allow(HTTParty).to receive(:post).and_return(mock_response)
    end

    context 'with successful API response' do
      let(:mock_response) {
        double(
          success?: true,
          body: {
            choices: [
              {
                message: {
                  content: 'We have several vegan options including salads and veggie burgers.'
                }
              }
            ]
          }.to_json
        )
      }

      it 'returns the completion text' do
        result = client.complete(prompt)
        
        expect(result).to eq('We have several vegan options including salads and veggie burgers.')
      end

      it 'sends correct request to API' do
        expect(HTTParty).to receive(:post).with(
          'https://api.deepseek.com/v1/chat/completions',
          hash_including(
            headers: hash_including('Authorization' => "Bearer #{api_key}"),
            body: anything
          )
        ).and_return(mock_response)

        client.complete(prompt)
      end

      it 'includes system message in Spanish' do
        expect(HTTParty).to receive(:post) do |url, options|
          body = JSON.parse(options[:body])
          system_message = body['messages'].find { |m| m['role'] == 'system' }
          
          expect(system_message['content']).to include('español')
        end.and_return(mock_response)

        client.complete(prompt)
      end
    end

    context 'with API error' do
      let(:mock_response) {
        double(
          success?: false,
          code: 500,
          body: 'Internal Server Error'
        )
      }

      it 'raises ApiError' do
        expect {
          client.complete(prompt)
        }.to raise_error(AiClient::ApiError, /DeepSeek API error/)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/DeepSeek complete error/)
        
        expect {
          client.complete(prompt)
        }.to raise_error(AiClient::ApiError)
      end
    end

    context 'with custom options' do
      let(:mock_response) {
        double(
          success?: true,
          body: { choices: [{ message: { content: 'Response' } }] }.to_json
        )
      }

      it 'respects temperature option' do
        expect(HTTParty).to receive(:post) do |url, options|
          body = JSON.parse(options[:body])
          expect(body['temperature']).to eq(0.5)
        end.and_return(mock_response)

        client.complete(prompt, temperature: 0.5)
      end

      it 'respects max_tokens option' do
        expect(HTTParty).to receive(:post) do |url, options|
          body = JSON.parse(options[:body])
          expect(body['max_tokens']).to eq(1000)
        end.and_return(mock_response)

        client.complete(prompt, max_tokens: 1000)
      end
    end
  end
end
