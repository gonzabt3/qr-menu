require 'rails_helper'

RSpec.describe ProductEmbeddingJob, type: :job do
  let(:product) { create(:product) }
  let(:mock_ai_client) { instance_double(AiClient::Deepseek) }
  let(:mock_embedding) { Array.new(1536) { rand } }

  before do
    allow(AiClient).to receive(:instance).and_return(mock_ai_client)
  end

  describe '#perform' do
    context 'with valid product' do
      it 'generates and stores embedding' do
        expect(mock_ai_client).to receive(:embed)
          .with(product.combined_text_for_embedding)
          .and_return(mock_embedding)

        described_class.perform_now(product.id)

        product.reload
        expect(product.embedding).to eq(mock_embedding)
        expect(product.embedding_generated_at).to be_present
      end

      it 'logs success' do
        allow(mock_ai_client).to receive(:embed).and_return(mock_embedding)
        
        expect(Rails.logger).to receive(:info)
          .with(/Generated embedding for product #{product.id}/)

        described_class.perform_now(product.id)
      end

      it 'skips if embedding is up to date' do
        time = Time.current
        product.update_columns(
          embedding: mock_embedding,
          embedding_generated_at: time,
          updated_at: time - 1.hour
        )

        expect(mock_ai_client).not_to receive(:embed)
        
        described_class.perform_now(product.id)
      end
    end

    context 'with non-existent product' do
      it 'logs warning and does not raise error' do
        expect(Rails.logger).to receive(:warn)
          .with(/Product 99999 not found/)

        expect {
          described_class.perform_now(99999)
        }.not_to raise_error
      end
    end

    context 'with AI client error' do
      it 'logs error and raises for retry' do
        error = AiClient::ApiError.new('API temporarily unavailable')
        allow(mock_ai_client).to receive(:embed).and_raise(error)

        expect(Rails.logger).to receive(:error)
          .with(/AI client error for product #{product.id}/)

        expect {
          described_class.perform_now(product.id)
        }.to raise_error(AiClient::ApiError)
      end
    end

    context 'with configuration error' do
      it 'logs error and does not retry' do
        error = AiClient::ConfigurationError.new('API key not set')
        allow(AiClient).to receive(:instance).and_raise(error)

        expect {
          described_class.perform_now(product.id)
        }.to raise_error(AiClient::ConfigurationError)
      end
    end

    context 'with unexpected error' do
      it 'logs error with backtrace and raises' do
        allow(mock_ai_client).to receive(:embed).and_raise(StandardError, 'Unexpected error')

        expect(Rails.logger).to receive(:error).at_least(:once)

        expect {
          described_class.perform_now(product.id)
        }.to raise_error(StandardError)
      end
    end
  end

  describe 'job configuration' do
    it 'is in default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    it 'retries on ApiError' do
      expect(described_class.retry_on).to include(AiClient::ApiError)
    end

    it 'discards on ConfigurationError' do
      expect(described_class.discard_on).to include(AiClient::ConfigurationError)
    end
  end
end
