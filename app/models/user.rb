class User < ApplicationRecord
  enum role: { staff: "staff", manager: "manager", admin: "admin" }
  has_many :comments, dependent: :destroy
  has_many :inquiries, dependent: :destroy
  validates :name, presence: true
  validates :role, presence: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
