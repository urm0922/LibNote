class AddForeignKeyToInquiriesUser < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :inquiries, :users
  end
end
