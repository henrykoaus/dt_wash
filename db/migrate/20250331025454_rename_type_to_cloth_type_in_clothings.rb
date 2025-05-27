class RenameTypeToClothTypeInClothings < ActiveRecord::Migration[7.1]
  def change
    rename_column :clothings, :type, :cloth_type
  end
end
