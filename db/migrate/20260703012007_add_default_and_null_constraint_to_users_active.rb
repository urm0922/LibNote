class AddDefaultAndNullConstraintToUsersActive < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :active, from: nil, to: true
    change_column_null :users, :active, false, true
  end
end
