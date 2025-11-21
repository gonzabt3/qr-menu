# frozen_string_literal: true

module Api
  class FeedbacksController < ApplicationController
    skip_before_action :authorize

    # POST /api/feedback
    def create
      feedback = Feedback.new(feedback_params)

      if feedback.save
        render json: {
          id: feedback.id,
          message: feedback.message,
          createdAt: feedback.created_at.iso8601
        }, status: :created
      else
        render json: { errors: feedback.errors.full_messages }, status: :bad_request
      end
    end

    # GET /api/feedbacks
    def index
      authenticate_with_secret!

      feedbacks = Feedback.order(created_at: :desc).limit(1000)
      render json: feedbacks.map { |f|
        {
          id: f.id,
          message: f.message,
          createdAt: f.created_at.iso8601
        }
      }, status: :ok
    end

    private

    def feedback_params
      params.require(:feedback).permit(:message)
    end

    def authenticate_with_secret!
      secret = ENV['FEEDBACK_READ_SECRET']
      
      if secret.blank?
        render json: { error: 'FEEDBACK_READ_SECRET not configured' }, status: :service_unavailable
        return
      end

      provided_secret = request.headers['X-Feedback-Secret'] || params[:secret]
      
      # Ensure provided_secret is a string and has the same length as secret to prevent timing leaks
      if provided_secret.blank? || 
         provided_secret.to_s.bytesize != secret.bytesize ||
         !ActiveSupport::SecurityUtils.secure_compare(secret, provided_secret.to_s)
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
