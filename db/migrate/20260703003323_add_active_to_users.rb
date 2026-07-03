class AddActiveToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :Active, :boolean
  end
end
