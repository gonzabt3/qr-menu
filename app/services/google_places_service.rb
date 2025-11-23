require 'net/http'
require 'uri'
require 'json'

class GooglePlacesService
  BASE = "https://maps.googleapis.com/maps/api/place"

  def initialize(api_key: ENV['GOOGLE_PLACES_API_KEY'])
    raise "GOOGLE_PLACES_API_KEY not set" unless api_key.present?
    @api_key = api_key
  end

  # Search restaurants around a lat/lng within radius (meters).
  def nearby_search(lat:, lng:, radius: 2000, keyword: nil, max_pages: 3)
    results = []
    next_page_token = nil
    max_pages.times do
      uri = URI("#{BASE}/nearbysearch/json")
      params = {
        key: @api_key,
        location: "#{lat},#{lng}",
        radius: radius,
        type: "restaurant"
      }
      params[:keyword] = keyword if keyword.present?
      params[:pagetoken] = next_page_token if next_page_token.present?
      uri.query = URI.encode_www_form(params)

      res = http_get(uri)
      parsed = JSON.parse(res.body)
      results += parsed["results"] || []
      next_page_token = parsed["next_page_token"]
      break unless next_page_token.present?
      sleep 2
    end
    results
  end

  # Fetch Place Details for a place_id
  def place_details(place_id)
    uri = URI("#{BASE}/details/json")
    params = {
      key: @api_key,
      place_id: place_id,
      fields: "place_id,name,formatted_address,geometry,formatted_phone_number,website,url,opening_hours"
    }
    uri.query = URI.encode_www_form(params)
    res = http_get(uri)
    JSON.parse(res.body)["result"]
  end

  private

  def http_get(uri)
    req = Net::HTTP::Get.new(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    http.open_timeout = 5
    response = http.request(req)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("Google Places API error: #{response.code} #{response.message} for #{uri}")
    end
    response
  rescue => e
    Rails.logger.error("HTTP error in GooglePlacesService: #{e.class} #{e.message}")
    raise
  end
end
