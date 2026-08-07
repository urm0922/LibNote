class Inquiry < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :approver,
              class_name: "User",
              optional: true
  has_many :comments, dependent: :destroy
  # ナレッジ化後は記事を保全するため、紐づく問い合わせは管理者でも削除させない。
  has_one :knowledge_article, dependent: :restrict_with_error
  has_many_attached :images
  validates :images, 
    limit: { max: 3, message: 'は3枚までしか投稿できません' },
    size: { less_than_or_equal_to: 5.megabytes, message: 'は1枚あたり5MB以下にしてください' }, 
    content_type: { in: %w[image/jpeg image/png image/webp], message: 'はJPEG、PNG、WEBP形式のみアップロード可能です' }
  validates :title, presence: true
  validates :body, presence: true
  validates :status, presence: true
  validates :approved_at, presence: true, if: :approved?
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
