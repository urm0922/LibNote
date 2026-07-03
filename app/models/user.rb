class User < ApplicationRecord
  scope :active_users, -> { where(active: true, deleted_at: nil) }
  scope :inactive_users, -> { where(active: false) }
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> {where.not(deleted_at: nil) }

  def soft_delete!
    update!(active_false, deleted_at: Time.current)
  end

  def deactivate!
    update!(active: false)
  end
  
  def active_for_authentication?
    super && active? && deleted_at.nil?
  end

  def inactive_message
    active? ? super : :inactive
  end

  enum role: { staff: "staff", manager: "manager", admin: "admin" }
  has_many :comments, dependent: :destroy
  has_many :inquiries, dependent: :restrict_with_error
  validates :name, presence: true
  validates :role, presence: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
