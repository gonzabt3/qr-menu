module Qr
  class WifiController < ApplicationController
    # Public endpoint to generate WiFi QR codes
    def show
      ssid = params[:ssid]
      auth = params[:auth] || 'WPA'
      password = params[:password]
      hidden = params[:hidden]
      format = (params[:format] || 'png').to_s.downcase

      # Validate required parameters
      render json: { error: 'ssid is required' }, status: :bad_request and return if ssid.blank?

      begin
        service = WifiQrService.new(ssid: ssid, auth: auth, password: password, hidden: hidden)
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request and return
      end

      case format
      when 'png'
        begin
          data = service.qr_png
          send_data data, type: 'image/png', disposition: 'inline'
        rescue StandardError
          render json: { error: 'failed to generate png' }, status: :internal_server_error
        end
      when 'svg'
        begin
          data = service.qr_svg
          send_data data, type: 'image/svg+xml', disposition: 'inline'
        rescue StandardError
          render json: { error: 'failed to generate svg' }, status: :internal_server_error
        end
      else
        render json: { error: 'invalid format' }, status: :bad_request
      end
    end
  end
end
