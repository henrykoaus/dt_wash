class SetDefaultStatusForOrders < ActiveRecord::Migration[7.1]
  def change
    # Update existing records (optional but recommended)
    reversible do |dir|
      dir.up { Order.where(status: nil).update_all(status: 0) }
    end
    # Set default value and prevent nulls
    change_column_default :orders, :status, from: nil, to: 0
    change_column_null :orders, :status, false


  end
end
