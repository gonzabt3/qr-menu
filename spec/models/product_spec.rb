require 'rails_helper'

RSpec.describe Product, type: :model do
  let!(:restaurant) { create(:restaurant) }
  let!(:menu) { create(:menu, restaurant: restaurant) }
  let!(:section) { create(:section, menu: menu) }
  let(:product) do
    create(:product,
           section: section,
           name: 'Pizza Margarita',
           description: 'Pizza con tomate y queso',
           price: 12.5,
           is_vegan: false,
           is_celiac: true)
  end

  describe '#combined_text_for_embedding' do
    it 'combines product attributes into a single text' do
      text = product.combined_text_for_embedding

      expect(text).to include('Nombre: Pizza Margarita')
      expect(text).to include('Descripción: Pizza con tomate y queso')
      expect(text).to include('Precio: $12.5')
    end

    it 'includes dietary information when present' do
      text = product.combined_text_for_embedding

      expect(text).to include('celíaco')
      expect(text).not_to include('vegano')
    end

    it 'handles vegan products' do
      vegan_product = create(:product,
                             section: section,
                             name: 'Ensalada',
                             is_vegan: true,
                             is_celiac: false)

      text = vegan_product.combined_text_for_embedding

      expect(text).to include('vegano')
      expect(text).not_to include('celíaco')
    end

    it 'handles products with both dietary flags' do
      both_product = create(:product,
                            section: section,
                            name: 'Ensalada especial',
                            is_vegan: true,
                            is_celiac: true)

      text = both_product.combined_text_for_embedding

      expect(text).to include('vegano')
      expect(text).to include('celíaco')
    end

    it 'handles products with minimal information' do
      minimal_product = build(:product,
                              section: section,
                              name: 'Simple',
                              description: nil,
                              is_vegan: false,
                              is_celiac: false)

      text = minimal_product.combined_text_for_embedding

      expect(text).to include('Nombre: Simple')
      expect(text).not_to include('Apto para:')
    end
  end

  describe 'embedding job enqueuing' do
    context 'when FEATURE_AI_CHAT_ENABLED is true' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FEATURE_AI_CHAT_ENABLED').and_return('true')
      end

      it 'enqueues ProductEmbeddingJob on create' do
        expect(ProductEmbeddingJob).to receive(:perform_async)

        create(:product, section: section, name: 'New Product', price: 10)
      end

      it 'enqueues ProductEmbeddingJob on update' do
        product # Create the product first
        
        expect(ProductEmbeddingJob).to receive(:perform_async)

        product.update(name: 'Updated Name')
      end
    end

    context 'when FEATURE_AI_CHAT_ENABLED is false' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FEATURE_AI_CHAT_ENABLED').and_return('false')
      end

      it 'does not enqueue ProductEmbeddingJob on create' do
        expect(ProductEmbeddingJob).not_to receive(:perform_async)

        create(:product, section: section, name: 'New Product', price: 10)
      end

      it 'does not enqueue ProductEmbeddingJob on update' do
        product # Create the product first

        expect(ProductEmbeddingJob).not_to receive(:perform_async)

        product.update(name: 'Updated Name')
      end
    end
  end
end
