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

  test "can attach an image" do
    inquiry = inquiries(:staff_open)

    inquiry.images.attach(
      io: File.open(file_fixture("sample1.png")),
      filename: "sample1.png",
      content_type: "image/png"
    )

    assert inquiry.images.attached?
    assert_equal 1, inquiry.images.count
    assert_equal "sample1.png", inquiry.images.first.filename.to_s
    assert_equal "image/png", inquiry.images.first.content_type
  end

  test "images over 5megabytes are invalid" do
    inquiry = Inquiry.new(
      title: "title",
      body: "body",
      status: :draft,
      user: users(:staff),
      category: categories(:general)
    )
  
    inquiry.images.attach(
      io: StringIO.new("a" * (5.megabytes + 1)),
      filename: "large.png",
      content_type: "image/png",
      identify: false
    )
  
    assert_not inquiry.valid?
    assert_includes inquiry.errors[:images],
                    "は1枚あたり5MB以下にしてください"
  end

  test "invalid unless it is an allowed file type" do
    inquiry = Inquiry.new(
      title: "title",
      body: "body",
      status: :draft,
      user: users(:staff),
      category: categories(:general)
    )

    inquiry.images.attach(
      io: StringIO.new("dummy"),
      filename: "image.gif",
      content_type: "image/gif",
      identify: false
    )

    assert_not inquiry.valid?
    assert_includes inquiry.errors[:images], "はJPEG、PNG、WEBP形式のみアップロード可能です" 
  end

  test "cannot destroy inquiry linked to knowledge article" do
    inquiry = inquiries(:staff_approved)
  
    assert_no_difference "Inquiry.count" do
      assert_not inquiry.destroy
    end
  
    assert inquiry.errors.present?
  end

end