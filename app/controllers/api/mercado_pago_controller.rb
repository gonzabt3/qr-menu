require 'mercadopago'
require 'net/http'
require 'uri'

module Api
  class MercadoPagoController < ApplicationController
    # protect_from_forgery with: :null_session

    def info
      event_type = params[:type]
      resource_id = params[:id]

      uri = URI.parse("https://api.mercadopago.com/preapproval/#{resource_id}")
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{ENV['MERCADO_PAGO_ACCESS_TOKEN']}"

      req_options = {
        use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      response_body = JSON.parse(response.body)

      # Buscar al usuario por subscription_id
      user = User.find_by(subscription_id: resource_id)

      return render json: { error: 'User not found' }, status: :not_found unless user

      # Actualizar el campo subscribed basado en el valor de semaphore
      semaphore = response_body.dig('summarized', 'semaphore')
      user.update(subscribed: false) if semaphore != 'green' && semaphore != 'yellow'

      # Si no se encuentra al usuario, devolver un error

      render json: JSON.parse(response.body), status: response.code.to_i
    end
  end
end
