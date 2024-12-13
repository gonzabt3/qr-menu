class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :auth0_id, null: false
      t.string :email, null: false
      t.string :name                              
      t.string :surname
      t.string :picture                           
      t.string :phone
      t.string :address
      t.string :birthday

      t.timestamps
    end
  end
end
