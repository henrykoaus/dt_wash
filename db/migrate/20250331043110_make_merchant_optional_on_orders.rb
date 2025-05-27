class MakeMerchantOptionalOnOrders < ActiveRecord::Migration[7.1]
  def change
    change_column_null :orders, :merchant_id, true
  end
end
