class RenamePriceToTotalPriceInOrders < ActiveRecord::Migration[7.1]
  def change
    rename_column :orders, :price, :total_price
  end
end
