class AddApproverToInquiries < ActiveRecord::Migration[7.1]
  def change
    add_reference :inquiries, :approver, null: true, foreign_key: { to_table: :users }
  end
end
