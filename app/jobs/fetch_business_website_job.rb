class FetchBusinessWebsiteJob < ApplicationJob
  queue_as :default

  def perform(business_id)
    business = Business.find_by(id: business_id)
    return unless business

    begin
      if business.website.present?
        scanner = WebsiteScanner.new(business.website)
        result = scanner.scan
        business.instagram = business.instagram.presence || result[:instagram]
        business.add_menu_urls(result[:menu_urls])
        business.status = "scanned"
        business.raw_response = (business.raw_response || {}).merge(scanned_at: Time.current, scanner_summary: result)
        business.save!
      else
        business.status = "failed"
        business.raw_response = (business.raw_response || {}).merge(error: "no website")
        business.save!
      end
    rescue => e
      business.status = "failed"
      business.raw_response = (business.raw_response || {}).merge(error: e.message)
      business.save!
      Rails.logger.error("FetchBusinessWebsiteJob failed for #{business.id}: #{e.message}")
    end
  end
end
