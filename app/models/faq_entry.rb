class FaqEntry < ApplicationRecord
  belongs_to :knowledge_article
  has_one :inquiry, through: :knowledge_article

  enum status: { draft: 0, published: 1,archived: 2}

  validates :question, presence: true
  validates :answer, presence: true
  validates :status, presence: true
end
