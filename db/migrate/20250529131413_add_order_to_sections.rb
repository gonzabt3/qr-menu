class AddOrderToSections < ActiveRecord::Migration[7.1]
  def change
    add_column :sections, :order, :integer, default: 0
  end
end
