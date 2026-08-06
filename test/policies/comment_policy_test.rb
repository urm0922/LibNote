require 'test_helper'

class CommentPolicyTest < ActiveSupport::TestCase
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles, "active_storage/blobs", "active_storage/attachments"
  
  test "staff can create and destroy comments only own open or draft, answered inquiries" do
    user = users(:staff)
    
    %w[draft open answered].each do |status|
      inquiry = inquiries(:"staff_#{status}")
      comment = inquiry.comments.build(user: user, body: "test comment")
      policy = CommentPolicy.new(user, comment)

      assert policy.create?, "staff should create comment on #{status} inquiry"
      assert policy.destroy?, "staff should destroy own comment on #{status} inquiry"
    end
    
    comment = inquiries(:staff_approved).comments.build(
      user: user,
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)

    assert_not policy.create?
    assert_not policy.destroy?

    comment = inquiries(:staff_rejected).comments.build(
      user: user,
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)

    assert_not policy.create?
    assert_not policy.destroy?

    inquiry = inquiries(:other_staff_open)
    comment = inquiry.comments.build(user: users(:staff), body: "test comment")
    policy = CommentPolicy.new(users(:staff), comment)

    assert_not policy.create?
    assert_not policy.destroy?
  end

  test "manager can create and destroy own comments on other's inquiries except draft and approved" do
    user = users(:manager)
    
    %w[open answered rejected].each do |status|
      inquiry = inquiries(:"staff_#{status}")
      comment = inquiry.comments.build(user: user, body: "test comment")
      policy = CommentPolicy.new(user, comment)

      assert policy.create?, "manager should create comment on #{status} inquiry"
      assert policy.destroy?, "manager should destroy own comment on #{status} inquiry"
    end
    
    comment = inquiries(:staff_draft).comments.build(
      user: user,
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)

    assert_not policy.create?
    assert_not policy.destroy?

    comment = inquiries(:staff_approved).comments.build(
      user: user,
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)

    assert_not policy.create?
    assert_not policy.destroy?
  end

  test "staff cannot destroy other's comment" do
    user = users(:staff)
    inquiry = inquiries(:staff_open)
    comment = inquiry.comments.build(
      user: users(:manager),
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)
    assert_not policy.destroy?
  end

  test "manager cannot destroy other's comment" do
    user = users(:manager)
    inquiry = inquiries(:staff_open)
    comment = inquiry.comments.build(
      user: users(:staff),
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)
    assert_not policy.destroy?
  end

  test "admin can create and destroy comments on any inquiries" do
    user = users(:admin)
    statuses = %w[draft open answered approved rejected]

    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
      comment = inquiry.comments.build(
        user: user,
        body: "test comment"
      )
      policy = CommentPolicy.new(user, comment)
      assert policy.create?, "admin should create comment on #{status} inquiry"
      assert policy.destroy?, "admin should destroy comment on #{status} inquiry"
    end

    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
      comment = inquiry.comments.build(
        user: users(:admin2),
        body: "test comment"
      )
      policy = CommentPolicy.new(user, comment)
      assert policy.destroy?, "admin should destroy other's comment on #{status} inquiry"
    end
  end

  test "manager cannot comment in other's draft inquiry" do
    user = users(:manager)
    inquiry = inquiries(:staff_draft)
    comment = inquiry.comments.build(
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)
    assert_not policy.create?
  end

  test "manager can comment own draft inquiry" do
    user = users(:manager)
    comment = inquiries(:manager_draft).comments.build(
      user: user,
      body: "test comment"
    )
    policy = CommentPolicy.new(user, comment)

    assert policy.create?
    assert policy.destroy?
  end
  
end