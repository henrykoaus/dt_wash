class AddCustomerAndMerchantToOrders < ActiveRecord::Migration[7.1]
  def change
    change_table :orders do |t|
      t.references :customer, null: false, foreign_key: { to_table: :users }
      t.references :merchant, null: false, foreign_key: { to_table: :users }
    end
  end
end
