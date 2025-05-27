class ChangePriceTypeInClothings < ActiveRecord::Migration[7.1]
  def up
    change_column :clothings, :price, :float
  end

  def down
    change_column :clothings, :price, :decimal, precision: 8, scale: 2
  end
end
