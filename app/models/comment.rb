class Comment < ApplicationRecord
  belongs_to :inquiry
  belongs_to :user
  validates :body, presence: true
end
