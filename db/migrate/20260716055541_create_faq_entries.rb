class CreateFaqEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :faq_entries do |t|
      t.references :knowledge_article, null: false, foreign_key: true
      t.text :question, null: false
      t.text :answer, null: false
      t.integer :status, null: false, default: 0
      t.boolean :generated_by_ai, null: false, default: false      
      t.datetime :published_at
      t.timestamps
    end
  end
end
