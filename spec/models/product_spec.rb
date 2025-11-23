require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:product) { create(:product) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:section) }
  end

  describe '#combined_text_for_embedding' do
    it 'combines product attributes into text' do
      product = build(:product, 
        name: 'Pizza Vegana',
        description: 'Pizza con verduras frescas',
        price: 15.50,
        is_vegan: true,
        is_celiac: false
      )

      text = product.combined_text_for_embedding
      
      expect(text).to include('Pizza Vegana')
      expect(text).to include('Pizza con verduras frescas')
      expect(text).to include('vegano')
      expect(text).to include('$15.5')
    end

    it 'handles missing optional fields' do
      product = build(:product, 
        name: 'Simple Product',
        description: nil,
        is_vegan: false,
        is_celiac: false
      )

      text = product.combined_text_for_embedding
      
      expect(text).to include('Simple Product')
      expect(text).not_to include('Descripción')
    end

    it 'includes dietary information when applicable' do
      product = build(:product, is_vegan: true, is_celiac: true)
      text = product.combined_text_for_embedding
      
      expect(text).to include('vegano')
      expect(text).to include('apto para celíacos')
    end
  end

  describe '#needs_embedding_regeneration?' do
    it 'returns true when embedding is nil' do
      product = build(:product, embedding: nil)
      expect(product.needs_embedding_regeneration?).to be true
    end

    it 'returns true when embedding_generated_at is nil' do
      product = build(:product, embedding: [0.1] * 1536, embedding_generated_at: nil)
      expect(product.needs_embedding_regeneration?).to be true
    end

    it 'returns true when product was updated after embedding generation' do
      product = create(:product)
      product.update_columns(
        embedding: [0.1] * 1536,
        embedding_generated_at: 1.hour.ago,
        updated_at: Time.current
      )
      expect(product.needs_embedding_regeneration?).to be true
    end

    it 'returns false when embedding is up to date' do
      product = create(:product)
      time = Time.current
      product.update_columns(
        embedding: [0.1] * 1536,
        embedding_generated_at: time,
        updated_at: time - 1.hour
      )
      expect(product.needs_embedding_regeneration?).to be false
    end
  end

  describe 'embedding generation callback' do
    it 'enqueues embedding job after create' do
      expect {
        create(:product)
      }.to have_enqueued_job(ProductEmbeddingJob)
    end

    it 'enqueues embedding job after update of relevant fields' do
      product = create(:product)
      # Clear the job queue from the create
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      
      expect {
        product.update(name: 'New Name')
      }.to have_enqueued_job(ProductEmbeddingJob).with(product.id)
    end

    it 'does not enqueue job when irrelevant fields change' do
      product = create(:product)
      # Clear the job queue from the create
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      
      # image_url is not part of the embedding generation trigger
      expect {
        product.update(image_url: 'http://example.com/new.jpg')
      }.not_to have_enqueued_job(ProductEmbeddingJob)
    end
  end

  describe 'scopes' do
    describe '.with_embeddings' do
      it 'returns only products with embeddings' do
        product_with = create(:product)
        product_with.update_columns(embedding: [0.1] * 1536)
        
        product_without = create(:product)
        product_without.update_columns(embedding: nil)

        results = Product.with_embeddings
        
        expect(results).to include(product_with)
        expect(results).not_to include(product_without)
      end
    end
  end
end
