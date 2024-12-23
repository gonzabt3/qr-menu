class CreateRestaurants < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurants do |t|
      t.string :name, null: false
      t.string :address
      t.string :phone
      t.string :email
      t.string :website
      t.string :instagram
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
