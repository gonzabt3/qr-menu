class CreateSections < ActiveRecord::Migration[7.1]
  def change
    create_table :sections do |t|
      t.string :name
      t.text :description
      t.references :menu, null: false, foreign_key: true

      t.timestamps
    end
  end
end
