class Business < ApplicationRecord
  validates :place_id, presence: true, uniqueness: true

  enum status: { pending: "pending", scanned: "scanned", failed: "failed" }

  # Helper to add menu urls
  def add_menu_urls(urls)
    self.menu_urls = (self.menu_urls || []) | urls
    self.has_menu = menu_urls.any?
    save!
  end
end
