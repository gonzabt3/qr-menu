class AddShowRestaurantLogoToDesignConfigurations < ActiveRecord::Migration[7.1]
  def change
    add_column :design_configurations, :show_restaurant_logo, :boolean, default: true
  end
end
