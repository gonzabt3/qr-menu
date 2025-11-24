module Admin
  class BusinessesController < ApplicationController
    before_action :authenticate_admin!

    def index
      @businesses = Business.order(created_at: :desc).limit(200)
      render json: @businesses.as_json(only: [:id, :name, :address, :phone, :website, :instagram, :has_menu, :menu_urls, :status])
    end

    def create
      lat = params[:lat] || params.dig(:center, :lat)
      lng = params[:lng] || params.dig(:center, :lng)
      radius = (params[:radius] || 2000).to_i
      keyword = params[:keyword]

      unless lat.present? && lng.present?
        return render json: { error: "lat and lng required" }, status: :bad_request
      end

      service = GooglePlacesService.new
      results = service.nearby_search(lat: lat, lng: lng, radius: radius, keyword: keyword)

      Rails.logger.info "Google Places API returned #{results.count} results"
      Rails.logger.info "Results: #{results.map { |r| r['name'] }.join(', ')}" if results.any?

      created = []
      results.each do |place|
        place_id = place['place_id']
        if Business.exists?(place_id: place_id)
          Rails.logger.info "Skipping existing business: #{place['name']} (#{place_id})"
          next
        end

        Rails.logger.info "Creating business: #{place['name']} (#{place_id})"

        details = service.place_details(place_id)
        business = Business.create!(
          place_id: details['place_id'],
          name: details['name'],
          address: details['formatted_address'],
          lat: details.dig('geometry','location','lat'),
          lng: details.dig('geometry','location','lng'),
          phone: details['formatted_phone_number'],
          website: details['website'],
          google_place_url: details['url'],
          raw_response: details
        )
        FetchBusinessWebsiteJob.perform_later(business.id)
        created << business
      end

      render json: { imported: created.count, details: created.map { |b| b.slice(:id, :name, :website) } }
    rescue => e
      Rails.logger.error("Admin::BusinessesController#create error: #{e.message}")
      render json: { error: e.message }, status: 500
    end

    private

    def authenticate_admin!
      authorize
      return unless validate_admin_access
    end
  end
end
