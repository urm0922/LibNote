require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "nameがあれば有効" do
    category = Category.new(
      name: "カテゴリー1"
    )

    assert category.valid?
  end
  
  test "nameがなければ無効" do
    category = Category.new(
      name: ""
    )

    assert_not category.valid?
  end
  
  test "nameが重複している場合は無効" do
    Category.create!(name: "利用者対応")

    category = Category.new(name: "利用者対応")

    assert_not category.valid?
  end
end
