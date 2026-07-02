class AddForeignKeyToInquiriesCategory < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :inquiries, :categories
  end
end
