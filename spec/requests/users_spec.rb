require 'rails_helper'

RSpec.describe 'UsersController', type: :request do
  describe 'POST /subscribe' do
    let(:user) { create(:user, email: 'test@example.com') }
    let(:valid_params) do
      {
        id: user.email,
        token: 'test_token',
        payer: { email: 'payer@example.com' }
      }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow(Mercadopago::SDK).to receive(:new).and_return(double('SDK',
                                                                 preapproval: double('Preapproval',
                                                                                     create: sdk_response)))
    end

    context 'when the subscription is successful' do
      let(:sdk_response) do
        {
          status: 201,
          response: {
            "id": '2c938084726fca480172750000000000',
            "version": 0,
            "application_id": 1_234_567_812_345_678,
            "collector_id": 100_200_300,
            "preapproval_plan_id": '2c938084726fca480172750000000000',
            "reason": 'Yoga classes.',
            "external_reference": user.id.to_s,
            "back_url": 'https://www.mercadopago.com.ar',
            "init_point": 'https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_id=2c938084726fca480172750000000000',
            "auto_recurring": {
              "frequency": 1,
              "frequency_type": 'months',
              "start_date": '2020-06-02T13:07:14.260Z',
              "end_date": '2022-07-20T15:59:52.581Z',
              "currency_id": 'ARS',
              "transaction_amount": 10,
              "free_trial": {
                "frequency": 1,
                "frequency_type": 'months'
              }
            },
            "payer_id": 123_123_123,
            "card_id": 123_123_123,
            "payment_method_id": 123_123_123,
            "next_payment_date": '2022-01-01T11:12:25.892-04:00',
            "date_created": '2022-01-01T11:12:25.892-04:00',
            "last_modified": '2022-01-01T11:12:25.892-04:00',
            "status": 'pending'
          }
        }
      end
      it "updates the user's subscription status" do
        post subscribe_user_path(user.email), params: valid_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['subscribed']).to be_truthy
      end
    end

    context 'when the subscription fails' do
      let(:sdk_response) do
        {
          status: 422,
          response: { message: 'Error' }
        }
      end

      it 'returns an error message' do
        post subscribe_user_path(user.email), params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Subscription failed')
      end
    end

    context 'when the user is not found' do
      let(:sdk_response) do
        {
          status: 201,
          response: {
            "id": '2c938084726fca480172750000000000',
            "version": 0,
            "application_id": 1_234_567_812_345_678,
            "collector_id": 100_200_300,
            "preapproval_plan_id": '2c938084726fca480172750000000000',
            "reason": 'Yoga classes.',
            "external_reference": user.id.to_s,
            "back_url": 'https://www.mercadopago.com.ar',
            "init_point": 'https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_id=2c938084726fca480172750000000000',
            "auto_recurring": {
              "frequency": 1,
              "frequency_type": 'months',
              "start_date": '2020-06-02T13:07:14.260Z',
              "end_date": '2022-07-20T15:59:52.581Z',
              "currency_id": 'ARS',
              "transaction_amount": 10,
              "free_trial": {
                "frequency": 1,
                "frequency_type": 'months'
              }
            },
            "payer_id": 123_123_123,
            "card_id": 123_123_123,
            "payment_method_id": 123_123_123,
            "next_payment_date": '2022-01-01T11:12:25.892-04:00',
            "date_created": '2022-01-01T11:12:25.892-04:00',
            "last_modified": '2022-01-01T11:12:25.892-04:00',
            "status": 'pending'
          }
        }
      end
      it 'returns a not found error' do
        post subscribe_user_path('user.email'), params: valid_params

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('User not found')
      end
    end
  end
end
