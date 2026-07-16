class AddGeneratedByAiToKnowledgeArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :knowledge_articles, :generated_by_ai, :boolean, null: false, default: false
  end
end
