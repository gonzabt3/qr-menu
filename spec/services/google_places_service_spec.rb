require 'rails_helper'

RSpec.describe GooglePlacesService, type: :service do
  let(:api_key) { 'test_api_key' }
  let(:service) { GooglePlacesService.new(api_key: api_key) }

  describe '#initialize' do
    it 'raises error when API key is not set' do
      expect { GooglePlacesService.new(api_key: nil) }.to raise_error('GOOGLE_PLACES_API_KEY not set')
    end

    it 'accepts API key parameter' do
      expect { service }.not_to raise_error
    end
  end

  describe '#nearby_search' do
    let(:lat) { -34.6037 }
    let(:lng) { -58.3816 }
    let(:mock_response) do
      {
        'results' => [
          {
            'place_id' => 'ChIJ1234567890',
            'name' => 'Test Restaurant',
            'vicinity' => 'Test Address'
          }
        ],
        'next_page_token' => nil
      }
    end

    before do
      stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/nearbysearch\/json/)
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'searches for restaurants near coordinates' do
      results = service.nearby_search(lat: lat, lng: lng, radius: 2000)
      expect(results).to be_an(Array)
      expect(results.first['place_id']).to eq('ChIJ1234567890')
      expect(results.first['name']).to eq('Test Restaurant')
    end

    it 'includes keyword in search when provided' do
      service.nearby_search(lat: lat, lng: lng, keyword: 'pizza')
      expect(WebMock).to have_requested(:get, /maps.googleapis.com/).with(query: hash_including('keyword' => 'pizza'))
    end
  end

  describe '#place_details' do
    let(:place_id) { 'ChIJ1234567890' }
    let(:mock_details) do
      {
        'result' => {
          'place_id' => place_id,
          'name' => 'Test Restaurant',
          'formatted_address' => '123 Test St',
          'geometry' => {
            'location' => { 'lat' => -34.6037, 'lng' => -58.3816 }
          },
          'formatted_phone_number' => '+54 11 1234-5678',
          'website' => 'http://example.com'
        }
      }
    end

    before do
      stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
        .to_return(status: 200, body: mock_details.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches place details for a place_id' do
      result = service.place_details(place_id)
      expect(result['place_id']).to eq(place_id)
      expect(result['name']).to eq('Test Restaurant')
      expect(result['website']).to eq('http://example.com')
    end
  end
end
