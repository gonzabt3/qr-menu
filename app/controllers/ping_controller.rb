# app/controllers/ping_controller.rb
class PingController < ApplicationController
  def index
    render json: { message: "pong #{ENV['CORS_ALLOWED_ORIGINS']}" }
  end
end
