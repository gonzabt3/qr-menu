# app/controllers/ping_controller.rb
class PingController < ApplicationController
  def index
    render json: { message: 'pong' }
  end
end
