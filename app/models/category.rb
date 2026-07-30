class Category < ApplicationRecord
  has_many :inquiries, dependent: :restrict_with_error
  has_many :knowledge_articles, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: true

  scope :search_keyword, ->(keyword) {
    if keyword.present?
      escaped_keyword = sanitize_sql_like(keyword)
      where("name LIKE :keyword", keyword: "%#{escaped_keyword}%")
    end
  }

  scope :latest, -> { order(created_at: :desc)}
  scope :old, -> { order(created_at: :asc)}
  scope :name_desc, -> { order(name: :desc)}
  scope :name_asc, -> { order(name: :asc)}
end
