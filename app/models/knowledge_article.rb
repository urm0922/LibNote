class KnowledgeArticle < ApplicationRecord
  belongs_to :inquiry
  belongs_to :category
  belongs_to :author, class_name: "User"
  enum status: { draft: 0, published: 1, archived: 2 }
  
  validates :title, presence: true
  validates :body, presence: true
  validates :status, presence: true
end
