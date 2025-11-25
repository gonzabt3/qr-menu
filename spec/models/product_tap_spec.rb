# spec/models/product_tap_spec.rb
require 'rails_helper'

RSpec.describe ProductTap, type: :model do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:section) { create(:section, menu: menu) }
  let(:product) { create(:product, section: section) }

  describe 'associations' do
    it { should belong_to(:product) }
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    it 'is valid with product_id and session_identifier' do
      product_tap = ProductTap.new(
        product_id: product.id,
        session_identifier: 'test-session'
      )
      expect(product_tap).to be_valid
    end

    it 'is valid with product_id and user_id' do
      product_tap = ProductTap.new(
        product_id: product.id,
        user_id: user.id
      )
      expect(product_tap).to be_valid
    end

    it 'is invalid without product_id' do
      product_tap = ProductTap.new(session_identifier: 'test-session')
      expect(product_tap).not_to be_valid
    end

    it 'is invalid without session_identifier when user_id is not present' do
      product_tap = ProductTap.new(product_id: product.id)
      expect(product_tap).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:tap1) { create(:product_tap, product: product, session_identifier: 'session-1', created_at: 1.day.ago) }
    let!(:tap2) { create(:product_tap, product: product, session_identifier: 'session-2', created_at: 2.days.ago) }
    let!(:tap3) { create(:product_tap, product: product, user: user, created_at: 3.days.ago) }

    describe '.recent' do
      it 'orders by created_at descending' do
        expect(ProductTap.recent.first).to eq(tap1)
        expect(ProductTap.recent.last).to eq(tap3)
      end
    end

    describe '.by_product' do
      let(:another_product) { create(:product, section: section) }
      let!(:other_tap) { create(:product_tap, product: another_product, session_identifier: 'session-x') }

      it 'returns only taps for specified product' do
        expect(ProductTap.by_product(product.id)).to include(tap1, tap2, tap3)
        expect(ProductTap.by_product(product.id)).not_to include(other_tap)
      end
    end

    describe '.by_user' do
      it 'returns only taps for specified user' do
        expect(ProductTap.by_user(user.id)).to eq([tap3])
      end
    end

    describe '.by_session' do
      it 'returns only taps for specified session' do
        expect(ProductTap.by_session('session-1')).to eq([tap1])
      end
    end

    describe '.in_date_range' do
      it 'returns taps within date range' do
        taps = ProductTap.in_date_range(2.days.ago, Time.current)
        expect(taps).to include(tap1, tap2)
        expect(taps).not_to include(tap3)
      end
    end
  end

  describe '.count_by_product' do
    let(:product2) { create(:product, section: section) }
    let!(:tap1) { create(:product_tap, product: product, session_identifier: 'session-1') }
    let!(:tap2) { create(:product_tap, product: product, session_identifier: 'session-2') }
    let!(:tap3) { create(:product_tap, product: product2, session_identifier: 'session-3') }

    it 'returns count of taps per product' do
      counts = ProductTap.count_by_product
      expect(counts[product.id]).to eq(2)
      expect(counts[product2.id]).to eq(1)
    end
  end
end
