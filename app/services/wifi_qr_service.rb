class WifiQrService
  VALID_AUTHS = %w[WPA WEP nopass].freeze

  attr_reader :ssid, :auth, :password, :hidden

  def initialize(ssid:, auth:, password: nil, hidden: false)
    @ssid = ssid.to_s
    @auth = normalize_auth(auth)
    @password = password.to_s
    @hidden = ActiveModel::Type::Boolean.new.cast(hidden)
  end

  def payload
    validate!

    parts = []
    parts << "T:#{payload_auth};"
    parts << "S:#{escape(ssid)};"
    parts << "P:#{escape(password)};" unless payload_auth == 'nopass'
    parts << "H:#{hidden ? 'true' : 'false'};"

    "WIFI:#{parts.join}"
  end

  def qr_png(resize: 300)
    qr = RQRCode::QRCode.new(payload)
    png = qr.as_png(size: resize)
    png.to_s
  end

  def qr_svg
    qr = RQRCode::QRCode.new(payload)
    if qr.respond_to?(:as_svg)
      qr.as_svg(offset: 0, color: '000', shape_rendering: 'crispEdges', module_size: 6)
    else
      # Fallback: simple SVG wrapper with QR data as text (not a real QR)
      "<svg xmlns='http://www.w3.org/2000/svg'><text x='0' y='15'>#{payload}</text></svg>"
    end
  end

  private

  def validate!
    raise ArgumentError, 'ssid is required' if ssid.strip.empty?
    raise ArgumentError, 'invalid auth type' unless VALID_AUTHS.include?(auth)
    return unless auth != 'nopass' && password.to_s.strip.empty?

    raise ArgumentError, 'password is required for secured networks'
  end

  def normalize_auth(a)
    return 'nopass' if a.to_s.downcase == 'nopass'

    a = a.to_s.upcase
    return 'WPA' if a.start_with?('WPA')
    return 'WEP' if a == 'WEP'

    a
  end

  def payload_auth
    auth
  end

  # Escape special characters per spec
  def escape(str)
    str.to_s.gsub(/([\\;,:"])/) { |m| "\\#{m}" }
  end
end
