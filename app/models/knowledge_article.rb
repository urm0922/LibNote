class KnowledgeArticle < ApplicationRecord
  belongs_to :inquiry
  belongs_to :category
  belongs_to :author, class_name: "User"
  has_many :faq_entries, dependent: :destroy
  enum status: { draft: 0, published: 1, archived: 2 }
  
  scope :published, -> { where(status: :published)}

  scope :search_keyword, ->(keyword) {
    if keyword.present?
      escaped_keyword = sanitize_sql_like(keyword)
      where("title LIKE :keyword OR body LIKE :keyword", keyword: "%#{escaped_keyword}%")
    end
  }

  scope :by_category, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }

  scope :by_status, ->(status) {
    where(status: statuses[status]) if status.present? && statuses.key?(status)
  }
 
  validates :title, presence: true
  validates :body, presence: true
  validates :status, presence: true
  validates :published_at, presence: true, if: :published?
end
