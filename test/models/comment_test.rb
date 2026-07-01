require "test_helper"

class CommentTest < ActiveSupport::TestCase

  def setup
    @user = User.create!(
      name: "ユーザー1",
      role: "staff",
      email: "comment-test@example.com",
      password: "password"
    )
    @category = Category.create!(name: "コメントテスト用カテゴリ")
    @inquiry = Inquiry.create!(
      title: "タイトル1",
      body: "本文1",
      user: @user,
      category: @category
    )
  end

  test "bodyがあれば有効" do
    comment = Comment.new(
      inquiry: @inquiry,
      user: @user,
      body: "確認しました。"
    )

    assert comment.valid?
  end

  test "bodyがなければ無効" do
    comment = Comment.new(
      inquiry: @inquiry,
      user: @user,
      body: ""
    )

    assert_not comment.valid?
  end

  test "inquiryがなければ無効" do
    comment = Comment.new(
      user: @user,
      body: "確認しました。"
    )

    assert_not comment.valid?
  end
  
  test "userがなければ無効" do
    comment = Comment.new(
      inquiry: @inquiry,
      body: "確認しました。"
    )

    assert_not comment.valid?
  end
end