class CreateProductTaps < ActiveRecord::Migration[7.1]
  def change
    create_table :product_taps do |t|
      t.bigint :product_id, null: false
      t.bigint :user_id
      t.string :session_identifier
      t.timestamps
    end

    add_index :product_taps, :product_id
    add_index :product_taps, :user_id
    add_index :product_taps, :session_identifier
    add_index :product_taps, :created_at
    add_foreign_key :product_taps, :products
    add_foreign_key :product_taps, :users
  end
end
