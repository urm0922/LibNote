class AddApprovedAtToInquiries < ActiveRecord::Migration[7.1]
  def change
    add_column :inquiries, :approved_at, :datetime, null: true
  end
end
