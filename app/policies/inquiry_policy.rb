class InquiryPolicy < ApplicationPolicy
  CREATABLE_STATUSES = %w[draft open].freeze

  ROLE_RULES = {
    "staff" => {
      editable: %w[draft open],
      destroyable: %w[draft open],
      assignable: %w[draft open]
    },
    "manager" => {
      editable: %w[draft open answered rejected],
      destroyable: %w[draft open answered rejected],
      assignable: %w[draft open]
    },
    "admin" => {
      editable: Inquiry.statuses.keys,
      destroyable: Inquiry.statuses.keys,
      assignable: Inquiry.statuses.keys
    }
  }.freeze

  def create?
    true
  end

  def show?
    accessible?
  end

  def edit?
    update?
  end

  def update?
    accessible? && current_status_allowed?(:editable)
  end

  def destroy?
    accessible? && current_status_allowed?(:destroyable)
  end

  def can_status_action?
    user.admin? || manager_can_process?
  end

  def mark_as_answered?
    user.admin? || manager_can_process?
  end

  def approve?
    user.admin?
  end

  def reject?
    user.admin? || manager_can_process?
  end

  def creatable_statuses
    CREATABLE_STATUSES
  end

  def permitted_statuses
    rules.fetch(:assignable)
  end

  private

  def manager_can_process?
    user.manager? && record.open?
  end

  def accessible?
    privileged? || owner?
  end

  def privileged?
    user.admin? || user.manager?
  end

  def owner?
    record.user_id == user.id
  end

  def current_status_allowed?(operation)
    rules.fetch(operation).include?(record.status)
  end

  def rules
    ROLE_RULES.fetch(user.role)
  end
end