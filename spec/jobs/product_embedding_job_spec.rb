require 'rails_helper'

RSpec.describe ProductEmbeddingJob, type: :job do
  let!(:restaurant) { create(:restaurant) }
  let!(:menu) { create(:menu, restaurant: restaurant) }
  let!(:section) { create(:section, menu: menu) }
  let!(:product) do
    create(:product,
           section: section,
           name: 'Pizza Margarita',
           description: 'Pizza con tomate y queso',
           price: 12.5,
           is_vegan: false)
  end

  describe '#perform' do
    context 'when product exists' do
      let(:mock_embedding) { [0.1, 0.2, 0.3] + [0.0] * 1533 }

      before do
        allow(AiClient).to receive(:embed).and_return(mock_embedding)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('false')
      end

      it 'generates and saves embedding for the product' do
        expect(AiClient).to receive(:embed).with(kind_of(String))

        ProductEmbeddingJob.new.perform(product.id)

        product.reload
        # Embedding is stored as string representation
        expect(product.embedding).to be_present
        expect(product.embedding_generated_at).to be_present
      end

      it 'calls combined_text_for_embedding on the product' do
        expect_any_instance_of(Product).to receive(:combined_text_for_embedding).and_call_original

        ProductEmbeddingJob.new.perform(product.id)
      end

      it 'updates embedding_generated_at timestamp' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        ProductEmbeddingJob.new.perform(product.id)

        product.reload
        # Allow for slight precision differences in timestamps
        expect(product.embedding_generated_at.to_i).to eq(freeze_time.to_i)
      end
    end

    context 'when product does not exist' do
      it 'does not raise an error' do
        expect {
          ProductEmbeddingJob.new.perform(99999)
        }.not_to raise_error
      end

      it 'logs an error when logging is enabled' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('true')

        expect(Rails.logger).to receive(:error).with(/Product 99999 not found/)

        ProductEmbeddingJob.new.perform(99999)
      end
    end

    context 'when product has minimal text' do
      let!(:minimal_product) do
        # Create with valid name first
        prod = create(:product,
               section: section,
               name: 'Temp',
               description: nil,
               price: 0)
        # Then clear the name bypassing validations
        prod.update_columns(name: '', description: nil, price: nil)
        prod
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('false')
      end

      it 'skips embedding generation when no meaningful text' do
        expect(AiClient).not_to receive(:embed)

        ProductEmbeddingJob.new.perform(minimal_product.id)
      end
    end

    context 'when AiClient raises an error' do
      before do
        allow(AiClient).to receive(:embed).and_raise(StandardError.new('API error'))
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('false')
      end

      it 're-raises the error for Sidekiq retry' do
        expect {
          ProductEmbeddingJob.new.perform(product.id)
        }.to raise_error(StandardError, 'API error')
      end

      it 'does not update the product embedding' do
        expect {
          ProductEmbeddingJob.new.perform(product.id) rescue nil
        }.not_to change { product.reload.embedding }
      end
    end

    context 'with logging enabled' do
      before do
        allow(AiClient).to receive(:embed).and_return([0.1] * 1536)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_AI_CHAT_LOGS').and_return('true')
      end

      it 'logs info messages' do
        expect(Rails.logger).to receive(:info).at_least(:once)

        ProductEmbeddingJob.new.perform(product.id)
      end
    end
  end
end
