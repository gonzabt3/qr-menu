# app/models/design_configuration.rb
class DesignConfiguration < ApplicationRecord
  belongs_to :menu

  validates :primary_color, presence: true
  validates :secondary_color, presence: true
  validates :background_color, presence: true
  validates :text_color, presence: true
  validates :font, presence: true

  # Validar que los colores sean válidos (formato hex)
  validates :primary_color, :secondary_color, :background_color, :text_color,
            format: { 
              with: /\A#[0-9A-Fa-f]{6}\z/, 
              message: "debe ser un color hexadecimal válido (ej: #ff7a00)" 
            }

  # Validar que la fuente sea una de las permitidas
  validates :font, inclusion: {
    in: %w[Inter Roboto Playfair\ Display Montserrat Poppins Open\ Sans Lato],
    message: "debe ser una fuente válida"
  }

  # Configuración por defecto
  def self.default_config
    {
      primary_color: "#ff7a00",
      secondary_color: "#64748b",
      background_color: "#fefaf4",
      text_color: "#1f2937",
      font: "Inter",
      logo_url: "",
      show_whatsapp: true,
      show_instagram: true,
      show_phone: true,
      show_maps: false,
      show_restaurant_logo: true
    }
  end

  # Obtener configuración como hash para enviar al frontend
  def to_design_hash
    {
      primaryColor: primary_color,
      secondaryColor: secondary_color,
      backgroundColor: background_color,
      textColor: text_color,
      font: font,
      logoUrl: logo_url || "",
      showWhatsApp: show_whatsapp,
      showInstagram: show_instagram,
      showPhone: show_phone,
      showMaps: show_maps,
      showRestaurantLogo: show_restaurant_logo
    }
  end

  # Actualizar desde hash del frontend
  def update_from_design_hash(design_hash)
    update!(
      primary_color: design_hash[:primaryColor] || design_hash["primaryColor"],
      secondary_color: design_hash[:secondaryColor] || design_hash["secondaryColor"],
      background_color: design_hash[:backgroundColor] || design_hash["backgroundColor"],
      text_color: design_hash[:textColor] || design_hash["textColor"],
      font: design_hash[:font] || design_hash["font"],
      logo_url: design_hash[:logoUrl] || design_hash["logoUrl"],
      show_whatsapp: design_hash[:showWhatsApp] || design_hash["showWhatsApp"],
      show_instagram: design_hash[:showInstagram] || design_hash["showInstagram"],
      show_phone: design_hash[:showPhone] || design_hash["showPhone"],
      show_maps: design_hash[:showMaps] || design_hash["showMaps"],
      show_restaurant_logo: design_hash[:showRestaurantLogo] || design_hash["showRestaurantLogo"]
    )
  end
end