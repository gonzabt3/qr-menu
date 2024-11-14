# app/controllers/ping_controller.rb
class PingController < ApplicationController
  before_action :authorize

  def index
    render json: { message: "holaaa" }
  end
end
