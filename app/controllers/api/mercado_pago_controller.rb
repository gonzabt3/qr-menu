require 'mercadopago'
require 'net/http'
require 'uri'

module Api
  class MercadoPagoController < ApplicationController
    # protect_from_forgery with: :null_session

    def info
      event_type = params[:type]
      resource_id = params[:id]

      uri = URI.parse("https://api.mercadopago.com/v1/payments/#{resource_id}")
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{ENV['MERCADO_PAGO_ACCESS_TOKEN']}"

      req_options = {
        use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      render json: JSON.parse(response.body), status: response.code.to_i
    end
  end
end
