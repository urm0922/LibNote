require 'test_helper'

class InquiryPolicyTest < ActiveSupport::TestCase
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles, "active_storage/blobs", "active_storage/attachments"

  test "manager can mark and reject only open inquiry " do
    user = users(:manager)
    inquiry = inquiries(:staff_open)

    assert InquiryPolicy.new(user, inquiry).mark_as_answered?

    inquiry = inquiries(:other_staff_open)
    assert InquiryPolicy.new(user, inquiry).reject?
  end

  test "manager cannot mark or reject non open inquiries" do
    user = users(:manager)
    statuses = %w[draft answered approved rejected]
    
    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
      assert_not InquiryPolicy.new(user, inquiry).mark_as_answered?, "manager should not mark #{status} as answered"
      assert_not InquiryPolicy.new(user, inquiry).reject?, "manager should not reject #{status}"
    end
  end

  test "staff can update and destroy inquiry only own draft and open" do
    user = users(:staff)
    inquiry = inquiries(:staff_open)

    assert InquiryPolicy.new(user, inquiry).update?
    assert InquiryPolicy.new(user, inquiry).destroy?

    inquiry = inquiries(:staff_draft)

    assert InquiryPolicy.new(user, inquiry).update?
    assert InquiryPolicy.new(user, inquiry).destroy?

    inquiry = inquiries(:other_staff_open)

    assert_not InquiryPolicy.new(user, inquiry).update?
    assert_not InquiryPolicy.new(user, inquiry).destroy?

    inquiry = inquiries(:staff_answered)
    
    assert_not InquiryPolicy.new(user, inquiry).update?
    assert_not InquiryPolicy.new(user, inquiry).destroy?

    inquiry = inquiries(:staff_approved)

    assert_not InquiryPolicy.new(user, inquiry).update?
    assert_not InquiryPolicy.new(user, inquiry).destroy?

    inquiry = inquiries(:staff_rejected)

    assert_not InquiryPolicy.new(user, inquiry).update?
    assert_not InquiryPolicy.new(user, inquiry).destroy?
  end

  test "staff cannot view other's inquiry detail" do
    user = users(:staff)
    inquiry = inquiries(:other_staff_open)

    assert_not InquiryPolicy.new(user, inquiry).show?
  end

  test "staff can view own inquiry detail" do
    policy = InquiryPolicy.new(
      users(:staff),
      inquiries(:staff_open)
    )
  
    assert policy.show?
  end

  test "admin can handle inquiries of any status" do
    user = users(:admin)
    statuses = %w[draft open answered rejected approved]
    actions = %w[show? edit? update? mark_as_answered? approve? reject?]
    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
        actions.each do |action|
          assert InquiryPolicy.new(user, inquiry).public_send(action), "admin should perform #{action} on #{status}"
        end
    end
  end

  test "admin can destroy inquiry of non-knowledge" do
    user = users(:admin)
    statuses = %w[draft open answered rejected]
    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
      policy = InquiryPolicy.new(user, inquiry)
      assert policy.destroy?, "admin should destroy #{status} inquiry"
    end
  end

  test "admin cannot destroy inquiry linked knowledge article" do
    policy = InquiryPolicy.new(
      users(:admin),
      inquiries(:staff_approved)
    )

    assert_not policy.destroy?
  end

  test "manager can assign only draft and open statuses" do
    policy = InquiryPolicy.new(
      users(:manager),
      inquiries(:staff_open)
    )

    assert_equal %w[draft open], policy.permitted_statuses
  end

  test "manager can update and destroy other's inquiries except draft and approved" do
    user = users(:manager)
    statuses = %w[open answered rejected]
    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
      policy = InquiryPolicy.new(user, inquiry)
      
      assert policy.update?, "manager should update #{status} inquiry"
      assert policy.destroy?, "manager should destroy #{status} inquiry"
    end

    draft_policy = InquiryPolicy.new(user, inquiries(:staff_draft))

    assert_not draft_policy.update?
    assert_not draft_policy.destroy?

    approved_policy = InquiryPolicy.new(user, inquiries(:staff_approved))

    assert_not approved_policy.update?
    assert_not approved_policy.destroy?
  end

  test "inquiry can be created only as draft or open" do
    policy = InquiryPolicy.new(
      users(:staff),
      inquiry = inquiries(:staff_open)
    )

    assert policy.create?
    assert_equal %w[draft open], policy.creatable_statuses
  end

  test "admin can handle another user's inquiry" do
    policy = InquiryPolicy.new(
      users(:admin),
      inquiries(:staff_draft)
    )

    assert policy.show?
    assert policy.update?
    assert policy.destroy?
  end

end

