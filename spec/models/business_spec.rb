require 'rails_helper'

RSpec.describe Business, type: :model do
  describe 'validations' do
    it 'validates presence of place_id' do
      business = Business.new(place_id: nil)
      expect(business.valid?).to be false
      expect(business.errors[:place_id]).to include("can't be blank")
    end

    it 'validates uniqueness of place_id' do
      Business.create!(place_id: 'test123', name: 'Test Restaurant')
      duplicate = Business.new(place_id: 'test123')
      expect(duplicate.valid?).to be false
      expect(duplicate.errors[:place_id]).to include('has already been taken')
    end
  end

  describe 'enum status' do
    it 'has new status by default' do
      business = Business.create!(place_id: 'test123')
      expect(business.status).to eq('new')
    end

    it 'can set scanned status' do
      business = Business.create!(place_id: 'test123')
      business.update(status: 'scanned')
      expect(business.status).to eq('scanned')
    end

    it 'can set failed status' do
      business = Business.create!(place_id: 'test123')
      business.update(status: 'failed')
      expect(business.status).to eq('failed')
    end
  end

  describe '#add_menu_urls' do
    let(:business) { Business.create!(place_id: 'test123') }

    it 'adds menu urls and sets has_menu to true' do
      business.add_menu_urls(['http://example.com/menu'])
      expect(business.menu_urls).to eq(['http://example.com/menu'])
      expect(business.has_menu).to be true
    end

    it 'prevents duplicate urls' do
      business.add_menu_urls(['http://example.com/menu'])
      business.add_menu_urls(['http://example.com/menu', 'http://example.com/menu2'])
      expect(business.menu_urls).to match_array(['http://example.com/menu', 'http://example.com/menu2'])
    end

    it 'handles empty arrays' do
      business.add_menu_urls([])
      expect(business.menu_urls).to eq([])
      expect(business.has_menu).to be false
    end
  end
end
