class ChangeBodyToTextInInquiries < ActiveRecord::Migration[7.1]
  def up
    change_column :inquiries, :body, :text, null: false
  end

  def down
    change_column :inquiries, :body, :string, null: false
  end
end
