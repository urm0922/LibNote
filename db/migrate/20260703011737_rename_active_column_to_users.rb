class RenameActiveColumnToUsers < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :Active, :active
  end
end
