require 'rails_helper'

RSpec.describe 'Api::FeedbacksController', type: :request do
  describe 'POST /api/feedback' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          feedback: {
            message: 'Great app! Love the QR menu feature.'
          }
        }
      end

      it 'creates a new feedback' do
        expect {
          post api_feedback_path, params: valid_params, as: :json
        }.to change(Feedback, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Great app! Love the QR menu feature.')
        expect(json_response['id']).to be_present
        expect(json_response['createdAt']).to be_present
      end
    end

    context 'with missing message' do
      let(:invalid_params) do
        {
          feedback: {
            message: ''
          }
        }
      end

      it 'returns a bad request error' do
        post api_feedback_path, params: invalid_params, as: :json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Message can't be blank")
      end
    end

    context 'with message too long' do
      let(:invalid_params) do
        {
          feedback: {
            message: 'a' * 2001
          }
        }
      end

      it 'returns a bad request error' do
        post api_feedback_path, params: invalid_params, as: :json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Message is too long (maximum is 2000 characters)')
      end
    end

    context 'without message parameter' do
      it 'returns a bad request error' do
        post api_feedback_path, params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET /api/feedbacks' do
    let!(:feedback1) { create(:feedback, message: 'First feedback', created_at: 2.days.ago) }
    let!(:feedback2) { create(:feedback, message: 'Second feedback', created_at: 1.day.ago) }
    let!(:feedback3) { create(:feedback, message: 'Third feedback', created_at: Time.current) }

    context 'with valid secret' do
      let(:secret) { 'test_secret_123' }

      before do
        ENV['FEEDBACK_READ_SECRET'] = secret
      end

      after do
        ENV.delete('FEEDBACK_READ_SECRET')
      end

      it 'returns all feedbacks in descending order by created_at' do
        get api_feedbacks_path, headers: { 'X-Feedback-Secret' => secret }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
        expect(json_response[0]['message']).to eq('Third feedback')
        expect(json_response[1]['message']).to eq('Second feedback')
        expect(json_response[2]['message']).to eq('First feedback')
      end

      it 'accepts secret as query parameter' do
        get api_feedbacks_path(secret: secret)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end
    end

    context 'with invalid secret' do
      before do
        ENV['FEEDBACK_READ_SECRET'] = 'correct_secret'
      end

      after do
        ENV.delete('FEEDBACK_READ_SECRET')
      end

      it 'returns unauthorized error' do
        get api_feedbacks_path, headers: { 'X-Feedback-Secret' => 'wrong_secret' }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'without secret configured' do
      before do
        ENV.delete('FEEDBACK_READ_SECRET')
      end

      it 'returns service unavailable error' do
        get api_feedbacks_path

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('FEEDBACK_READ_SECRET not configured')
      end
    end

    context 'without providing secret' do
      before do
        ENV['FEEDBACK_READ_SECRET'] = 'test_secret'
      end

      after do
        ENV.delete('FEEDBACK_READ_SECRET')
      end

      it 'returns unauthorized error' do
        get api_feedbacks_path

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
