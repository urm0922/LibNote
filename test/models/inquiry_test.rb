require "test_helper"

class InquiryTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "ユーザー1",
      role: "staff",
      email: "inquire-test@example.com",
      password: "password"
    )
    @category = Category.create!(name: "問い合わせテスト用カテゴリ")
  end

  test "titleとbodyがあれば有効" do
    inquiry = Inquiry.new(
      title: "タイトル1",
      body: "本文1",
      user: @user,
      category: @category
    )

    assert inquiry.valid?
  end

  test "titleがなければ無効" do
    inquiry = Inquiry.new(
      body: "本文1",
      user: @user,
      category: @category
    )

    assert_not inquiry.valid?
  end

  test "bodyがなければ無効" do
    inquiry = Inquiry.new(
      title: "タイトル1",
      user: @user,
      category: @category
    )

    assert_not inquiry.valid?
  end

  test "userがなければ無効" do
    inquiry = Inquiry.new(
      title: "タイトル1",
      body: "本文1",
      category: @category
    )

    assert_not inquiry.valid?
  end

  test "categoryがなければ無効" do
    inquiry = Inquiry.new(
      title: "タイトル1",
      body: "本文1",
      user: @user
    )

    assert_not inquiry.valid?
  end

  test "inquiryを削除するとcommentsも削除される" do
    inquiry = Inquiry.create!(
      title: "タイトル1",
      body: "本文1",
      user: @user,
      category: @category
    )
    inquiry.comments.create!(body: "コメント1", user: @user)
    assert_difference "Comment.count", -1 do
      inquiry.destroy
    end
  end
end
