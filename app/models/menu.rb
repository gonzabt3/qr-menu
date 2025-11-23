class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :sections, dependent: :destroy
  has_one :design_configuration, dependent: :destroy

  validates :name, presence: true

  # Obtener configuración de diseño, crear una por defecto si no existe
  def get_design_configuration
    design_configuration || create_design_configuration(DesignConfiguration.default_config)
  end

  # Obtener configuración como hash para el frontend
  def design_config_hash
    get_design_configuration.to_design_hash
  end
end
