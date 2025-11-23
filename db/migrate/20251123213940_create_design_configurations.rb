class CreateDesignConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :design_configurations do |t|
      t.references :menu, null: false, foreign_key: true, index: { unique: true }
      t.string :primary_color, default: "#ff7a00"
      t.string :secondary_color, default: "#64748b"
      t.string :background_color, default: "#fefaf4"
      t.string :text_color, default: "#1f2937"
      t.string :font, default: "Inter"
      t.text :logo_url
      t.boolean :show_whatsapp, default: true
      t.boolean :show_instagram, default: true
      t.boolean :show_phone, default: true
      t.boolean :show_maps, default: false

      t.timestamps
    end
  end
end
