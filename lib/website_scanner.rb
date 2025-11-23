require 'open-uri'
require 'nokogiri'
require 'uri'
require 'net/http'

class WebsiteScanner
  attr_reader :url

  USER_AGENT = "QRMenuBot/1.0 (+https://yourapp.example)"

  def initialize(url)
    @url = normalize_url(url)
  end

  # Returns a hash with keys: :menu_urls, :instagram
  def scan
    html = fetch(@url)
    doc = Nokogiri::HTML(html)
    links = doc.css('a').map { |a| a['href'].to_s.strip }.compact

    menu_urls = find_menu_links(links)
    instagram = find_instagram(links, doc)

    if menu_urls.empty?
      body_text = doc.xpath('//body').text.downcase
      if body_text.match?(/\b(menu|menú|carta|carta del restaurante|ver menú)\b/)
        menu_urls << @url
      end
    end

    { menu_urls: menu_urls.uniq, instagram: instagram }
  end

  private

  def normalize_url(u)
    return u if u =~ /\Ahttps?:\/\//
    "http://#{u}"
  end

  def fetch(u)
    uri = URI(u)
    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = USER_AGENT
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 10) do |http|
      http.request(req)
    end
    if res.is_a?(Net::HTTPSuccess)
      res.body
    else
      raise "Failed to fetch #{u}: #{res.code}"
    end
  end

  def absolute_link(href)
    return nil if href.blank?
    href = href.strip
    return nil if href.start_with?('javascript:') || href.start_with?('#') || href.start_with?('mailto:')
    begin
      URI.join(@url, href).to_s
    rescue URI::InvalidURIError, ArgumentError => e
      Rails.logger.debug("Invalid URI when joining #{@url} and #{href}: #{e.message}")
      nil
    end
  end

  def find_menu_links(links)
    candidates = []
    links.each do |l|
      abs = absolute_link(l)
      next unless abs
      down = abs.downcase
      if down.match?(/menu|menú|carta/i) || down.end_with?('.pdf')
        candidates << abs
      end
    end
    candidates
  end

  def find_instagram(links, doc)
    links.each do |l|
      abs = absolute_link(l)
      next unless abs
      begin
        uri = URI.parse(abs)
        # Check if the host is exactly instagram.com or a subdomain of instagram.com
        if uri.host && (uri.host == 'instagram.com' || uri.host.end_with?('.instagram.com'))
          path = uri.path
          if path
            user = path.split('/').reject(&:blank?).first
            return "https://instagram.com/#{user}" if user
          end
          return abs
        end
      rescue URI::InvalidURIError
        next
      end
    end
    nil
  end
end
