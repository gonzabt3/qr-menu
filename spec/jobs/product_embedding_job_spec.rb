# spec/jobs/product_embedding_job_spec.rb
require 'rails_helper'

RSpec.describe ProductEmbeddingJob, type: :job do
  let(:mock_embedding) { Array.new(1536) { rand } }
  
  # Create required associations
  let!(:user) { create(:user) }
  let!(:restaurant) { create(:restaurant, user: user) }
  let!(:menu) { create(:menu, restaurant: restaurant) }
  let!(:section) { create(:section, menu: menu) }
  let!(:product) { create(:product, section: section, name: 'Test Product', description: 'Test description') }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('false')
    allow(AiClient).to receive(:embed).and_return(mock_embedding)
  end

  describe '#perform' do
    context 'with valid product' do
      it 'generates and saves embedding' do
        expect {
          ProductEmbeddingJob.new.perform(product.id)
        }.to change { product.reload.embedding }.from(nil)

        expect(product.embedding).to eq(mock_embedding)
        expect(product.embedding_generated_at).to be_present
      end

      it 'calls AiClient.embed with combined text' do
        expected_text = product.combined_text_for_embedding
        expect(AiClient).to receive(:embed).with(expected_text).and_return(mock_embedding)
        
        ProductEmbeddingJob.new.perform(product.id)
      end
    end

    context 'with non-existent product' do
      it 'does not raise error' do
        expect {
          ProductEmbeddingJob.new.perform(99999)
        }.not_to raise_error
      end
    end

    context 'when AiClient raises an error' do
      before do
        allow(AiClient).to receive(:embed).and_raise(StandardError.new('API Error'))
      end

      it 'raises error for retry' do
        expect {
          ProductEmbeddingJob.new.perform(product.id)
        }.to raise_error(StandardError, 'API Error')
      end

      it 'does not update product embedding' do
        expect {
          begin
            ProductEmbeddingJob.new.perform(product.id)
          rescue StandardError
            nil
          end
        }.not_to change { product.reload.embedding }
      end
    end

    context 'with product without text' do
      let!(:empty_product) { create(:product, section: section, name: '', description: nil, price: 0) }

      before do
        # Allow validation to be bypassed for test
        empty_product.update_columns(name: '', description: nil)
      end

      it 'skips embedding generation' do
        expect(AiClient).not_to receive(:embed)
        ProductEmbeddingJob.new.perform(empty_product.id)
      end
    end
  end
end
