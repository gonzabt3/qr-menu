class AddIsVeganAndIsCeliacToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :is_vegan, :boolean, default: false
    add_column :products, :is_celiac, :boolean, default: false
  end
end
