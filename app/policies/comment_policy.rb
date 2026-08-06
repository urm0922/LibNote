class CommentPolicy < ApplicationPolicy
  COMMENTABLE_STATUSES = {
    "staff" => %w[draft open answered],
    "manager" => %w[draft open answered rejected],
    "admin" => Inquiry.statuses.keys
  }.freeze

  def create?
    inquiry_accessible? && commentable_status?
  end

  def destroy?
    create? && (user.admin? || owner?)
  end

  private

  def inquiry
    record.inquiry
  end

  def inquiry_accessible?
    InquiryPolicy.new(user, inquiry).show?
  end

  def commentable_status?
    COMMENTABLE_STATUSES.fetch(user.role).include?(inquiry.status)
  end

  def owner?
    record.user_id == user.id
  end
end