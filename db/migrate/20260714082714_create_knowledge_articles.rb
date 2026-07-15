class CreateKnowledgeArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledge_articles do |t|
      t.references :inquiry, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :body, null: false
      t.integer :status, default: 0, null: false
      t.boolean :faq_enabled, default: false, null: false
      t.datetime :published_at
      t.timestamps
    end
  end
end
