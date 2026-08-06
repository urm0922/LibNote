class FaqEntry < ApplicationRecord
  belongs_to :knowledge_article
  has_one :inquiry, through: :knowledge_article

  enum status: { draft: 0, published: 1,archived: 2}
  
  scope :publicly_visible, -> {
    published
      .joins(:knowledge_article)
      .merge(KnowledgeArticle.published.where(faq_enabled: true)
    )
  }

  scope :search_keyword, ->(keyword) {
    if keyword.present?
      escaped_keyword = sanitize_sql_like(keyword)
      where("faq_entries.question LIKE :keyword OR faq_entries.answer LIKE :keyword", keyword: "%#{escaped_keyword}%")
    end
  }

  validates :question, presence: true
  validates :answer, presence: true
  validates :status, presence: true
end
