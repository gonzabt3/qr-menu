class AddFavoriteToMenus < ActiveRecord::Migration[7.1]
  def change
    add_column :menus, :favorite, :boolean, default: false
  end
end
