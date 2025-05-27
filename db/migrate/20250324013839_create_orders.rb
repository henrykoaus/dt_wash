class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.integer :status
      t.string :address
      t.text :notes
      t.float :price

      t.timestamps
    end
  end
end
