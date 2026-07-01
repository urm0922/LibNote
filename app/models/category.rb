class Category < ApplicationRecord
  has_many :inquiries
  validates :name, presence: true, uniqueness: true
end
