class CreateClothings < ActiveRecord::Migration[7.1]
  def change
    create_table :clothings do |t|
      t.references :order, null: false, foreign_key: true
      t.string :color
      t.string :type

      t.timestamps
    end
  end
end
