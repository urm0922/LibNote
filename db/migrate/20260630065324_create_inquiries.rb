class CreateInquiries < ActiveRecord::Migration[7.1]
  def change
    create_table :inquiries do |t|
      t.string :title, null: false
      t.string :body, null: false
      t.integer :user_id, null: false
      t.integer :category_id, null: false
      t.integer :status, null: false, default: 0
   t.timestamps
    end
  end
end
