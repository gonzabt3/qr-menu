require 'rails_helper'

RSpec.describe Admin::BusinessesController, type: :request do
  let(:user) { create(:user, email: 'admin@example.com') }
  let(:admin_email) { 'admin@example.com' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ADMIN_EMAILS').and_return(admin_email)
    allow(ENV).to receive(:[]).with('GOOGLE_PLACES_API_KEY').and_return('test_api_key')
  end

  describe 'GET /admin/businesses' do
    before do
      create_list(:business, 3)
    end

    context 'when authenticated as admin' do
      before do
        allow_any_instance_of(Admin::BusinessesController).to receive(:authorize).and_return(true)
        allow_any_instance_of(Admin::BusinessesController).to receive(:validate_admin_access).and_return(true)
      end

      it 'returns list of businesses' do
        get '/admin/businesses'
        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(3)
      end

      it 'returns only specified fields' do
        get '/admin/businesses'
        json_response = JSON.parse(response.body)
        
        first_business = json_response.first
        expect(first_business.keys).to match_array(%w[id name address phone website instagram has_menu menu_urls status])
      end
    end

    context 'when not authenticated as admin' do
      before do
        allow_any_instance_of(Admin::BusinessesController).to receive(:authorize).and_return(true)
        allow_any_instance_of(Admin::BusinessesController).to receive(:validate_admin_access).and_return(false)
      end

      it 'returns forbidden' do
        get '/admin/businesses'
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /admin/businesses' do
    let(:lat) { -34.6037 }
    let(:lng) { -58.3816 }
    let(:params) { { lat: lat, lng: lng, radius: 2000 } }

    let(:mock_search_results) do
      [{ 'place_id' => 'ChIJ123' }]
    end

    let(:mock_place_details) do
      {
        'place_id' => 'ChIJ123',
        'name' => 'Test Restaurant',
        'formatted_address' => '123 Test St',
        'geometry' => { 'location' => { 'lat' => lat, 'lng' => lng } },
        'formatted_phone_number' => '+54 11 1234-5678',
        'website' => 'http://example.com',
        'url' => 'https://maps.google.com/place123'
      }
    end

    before do
      allow_any_instance_of(Admin::BusinessesController).to receive(:authorize).and_return(true)
      allow_any_instance_of(Admin::BusinessesController).to receive(:validate_admin_access).and_return(true)
      
      allow_any_instance_of(GooglePlacesService).to receive(:nearby_search).and_return(mock_search_results)
      allow_any_instance_of(GooglePlacesService).to receive(:place_details).and_return(mock_place_details)
      allow(FetchBusinessWebsiteJob).to receive(:perform_later)
    end

    context 'with valid parameters' do
      it 'creates businesses and enqueues jobs' do
        expect {
          post '/admin/businesses', params: params
        }.to change(Business, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['imported']).to eq(1)
        expect(FetchBusinessWebsiteJob).to have_received(:perform_later)
      end

      it 'does not create duplicate businesses' do
        Business.create!(place_id: 'ChIJ123', name: 'Existing')
        
        expect {
          post '/admin/businesses', params: params
        }.not_to change(Business, :count)

        json_response = JSON.parse(response.body)
        expect(json_response['imported']).to eq(0)
      end
    end

    context 'with missing parameters' do
      it 'returns bad request when lat is missing' do
        post '/admin/businesses', params: { lng: lng }
        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('lat and lng required')
      end

      it 'returns bad request when lng is missing' do
        post '/admin/businesses', params: { lat: lat }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when service raises an error' do
      before do
        allow_any_instance_of(GooglePlacesService).to receive(:nearby_search).and_raise(StandardError.new('API Error'))
      end

      it 'returns internal server error' do
        post '/admin/businesses', params: params
        expect(response).to have_http_status(500)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('API Error')
      end
    end
  end
end
