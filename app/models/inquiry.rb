class Inquiry < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  validates :title, presence: true
  validates :body, presence: true
  enum status: { draft: 0, open: 1, answered: 2, approved: 3, rejected: 4 }
end
