require 'rails_helper'

RSpec.describe AiClient::Openai, type: :service do
  let(:api_key) { 'test-openai-key' }
  
  before do
    allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(api_key)
  end

  describe '#initialize' do
    context 'with valid API key' do
      it 'initializes successfully' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'without API key' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      end

      it 'raises ConfigurationError' do
        expect {
          described_class.new
        }.to raise_error(AiClient::ConfigurationError, /OPENAI_API_KEY/)
      end
    end
  end

  describe '#embed' do
    let(:client) { described_class.new }
    let(:text) { 'Test product description' }
    
    before do
      allow(HTTParty).to receive(:post).and_return(mock_response)
    end

    context 'with successful API response' do
      let(:embedding_vector) { Array.new(1536) { rand(-1.0..1.0) } }
      let(:mock_response) {
        double(
          success?: true,
          body: {
            data: [
              { embedding: embedding_vector }
            ]
          }.to_json
        )
      }

      it 'returns the embedding vector' do
        result = client.embed(text)
        
        expect(result).to eq(embedding_vector)
      end

      it 'sends correct request to API' do
        expect(HTTParty).to receive(:post).with(
          'https://api.openai.com/v1/embeddings',
          hash_including(
            headers: hash_including('Authorization' => "Bearer #{api_key}"),
            body: anything
          )
        ).and_return(mock_response)

        client.embed(text)
      end

      it 'uses correct embedding model' do
        expect(HTTParty).to receive(:post) do |url, options|
          body = JSON.parse(options[:body])
          expect(body['model']).to eq('text-embedding-ada-002')
          expect(body['input']).to eq(text)
        end.and_return(mock_response)

        client.embed(text)
      end
    end

    context 'with blank text' do
      it 'returns zero vector without API call' do
        expect(HTTParty).not_to receive(:post)
        
        result = client.embed('')
        expect(result).to eq(Array.new(1536, 0.0))
      end
    end

    context 'with API error' do
      let(:mock_response) {
        double(
          success?: false,
          code: 429,
          body: 'Rate limit exceeded'
        )
      }

      it 'raises ApiError' do
        expect {
          client.embed(text)
        }.to raise_error(AiClient::ApiError, /OpenAI API error/)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/OpenAI embed error/)
        
        expect {
          client.embed(text)
        }.to raise_error(AiClient::ApiError)
      end
    end
  end

  describe '#complete' do
    let(:client) { described_class.new }
    let(:prompt) { 'What vegan options do you have?' }
    
    before do
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
          'https://api.openai.com/v1/chat/completions',
          hash_including(
            headers: hash_including('Authorization' => "Bearer #{api_key}"),
            body: anything
          )
        ).and_return(mock_response)

        client.complete(prompt)
      end

      it 'uses GPT-3.5-turbo model' do
        expect(HTTParty).to receive(:post) do |url, options|
          body = JSON.parse(options[:body])
          expect(body['model']).to eq('gpt-3.5-turbo')
        end.and_return(mock_response)

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
        }.to raise_error(AiClient::ApiError, /OpenAI API error/)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/OpenAI complete error/)
        
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
