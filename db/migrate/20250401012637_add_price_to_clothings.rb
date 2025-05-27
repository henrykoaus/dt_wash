class AddPriceToClothings < ActiveRecord::Migration[7.1]
  def change
    add_column :clothings, :price, :decimal, precision: 8, scale: 2

    # Remove all existing data
    Clothing.delete_all  end
end
