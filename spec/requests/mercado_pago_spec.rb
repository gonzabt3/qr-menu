require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Api::MercadoPagoController', type: :request do
  describe 'GET /info' do
    let(:user) { create(:user, subscription_id: '2c938084726fca480172750000000000', subscribed: true) }
    let(:valid_params) do
      {
        type: 'preapproval',
        id: user.subscription_id
      }
    end

    before do
      stub_request(:get, "https://api.mercadopago.com/preapproval/#{user.subscription_id}")
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, 'https://api.mercadopago.com/preapproval/nonexistent_subscription_id')
        .to_return(status: 404, body: { error: 'not_found' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when the semaphore is not green or yellow' do
      let(:response_body) do
        {
          "id": '2c938084726fca480172750000000000',
          "summarized": {
            "semaphore": 'red'
          }
        }
      end

      it 'updates the user subscribed status to false' do
        post api_mercado_pago_path(valid_params)

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.subscribed).to be_falsey
      end
    end

    context 'when the semaphore is green' do
      let(:response_body) do
        {
          "id": '2c938084726fca480172750000000000',
          "summarized": {
            "semaphore": 'green'
          }
        }
      end

      it 'does not update the user subscribed status' do
        post api_mercado_pago_path(valid_params)

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.subscribed).to be_truthy
      end
    end

    context 'when the semaphore is yellow' do
      let(:response_body) do
        {
          "id": '2c938084726fca480172750000000000',
          "summarized": {
            "semaphore": 'yellow'
          }
        }
      end

      it 'does not update the user subscribed status' do
        post api_mercado_pago_path(valid_params)

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.subscribed).to be_truthy
      end
    end

    context 'when the user is not found' do
      let(:response_body) do
        {
          "id": '2c938084726fca480172750000000000',
          "summarized": {
            "semaphore": 'red'
          }
        }
      end
      let(:valid_params) do
        { type: 'preapproval', id: 'nonexistent_subscription_id' }
      end
      it 'returns a not found error' do
        post api_mercado_pago_path(valid_params)

        expect(response).to have_http_status(404)
      end
    end
  end
end
