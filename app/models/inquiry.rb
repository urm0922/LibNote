class Inquiry < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  validates :title, presence: true
  validates :body, presence: true
  validates :status, presence: true
  enum status: { draft: 0, open: 1, answered: 2, approved: 3, rejected: 4 }

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

  scope :approved_knowledge, -> {
    approved.includes(:category, :user).order(updated_at: :desc)
  }
end
