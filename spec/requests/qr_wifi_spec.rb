require 'rails_helper'

RSpec.describe 'QR Wifi endpoint', type: :request do
  describe 'GET /qr/wifi' do
    it 'returns png for valid request' do
      get '/qr/wifi', params: { ssid: 'Office', auth: 'WPA', password: 'pass' }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('image/png')
      expect(response.body.length).to be > 0
    end

    it 'returns svg for format=svg' do
      get '/qr/wifi', params: { ssid: 'Office', auth: 'WPA', password: 'pass', format: 'svg' }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('image/svg+xml')
      expect(response.body).to include('WIFI:')
    end

    it 'works with open network (nopass)' do
      get '/qr/wifi', params: { ssid: 'OpenWifi', auth: 'nopass' }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('image/png')
    end

    it 'works with hidden network parameter' do
      get '/qr/wifi', params: { ssid: 'HiddenNet', auth: 'WPA', password: 'secret', hidden: 'true' }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('image/png')
    end

    it 'returns error for invalid format' do
      get '/qr/wifi', params: { ssid: 'Office', auth: 'WPA', password: 'pass', format: 'gif' }
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['error']).to eq('invalid format')
    end

    it 'returns error for missing ssid' do
      get '/qr/wifi', params: { ssid: '', auth: 'WPA', password: 'pass' }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns error for missing password in secured network' do
      get '/qr/wifi', params: { ssid: 'SecureNet', auth: 'WPA', password: '' }
      expect(response).to have_http_status(:bad_request)
    end
  end
end
