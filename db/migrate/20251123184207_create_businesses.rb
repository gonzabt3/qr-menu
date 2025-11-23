class CreateBusinesses < ActiveRecord::Migration[7.0]
  def change
    create_table :businesses do |t|
      t.string :place_id, null: false, index: { unique: true }
      t.string :name
      t.string :address
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lng, precision: 10, scale: 6
      t.string :phone
      t.string :website
      t.string :google_place_url
      t.string :instagram
      t.boolean :has_menu, default: false
      t.jsonb :menu_urls, default: []
      t.jsonb :raw_response, default: {}
      t.string :status, default: "new"
      t.timestamps
    end
  end
end
