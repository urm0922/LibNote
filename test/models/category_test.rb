require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles, :faq_entries
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

  test "can destroy unused category" do
    category = categories(:unused)
    assert_difference "Category.count", -1 do
      category.destroy
    end
  end

  test "cannot destroy category used by inquiry" do
    category = categories(:general)
    assert_difference "Category.count", 0 do
      category.destroy
    end
  end

  test "cannot destroy category used by knowledge" do
    category = categories(:used_by_knowledge)
    assert_difference "Category.count", 0 do
      category.destroy
    end
  end

  test "latest orders categories by newest created_at first" do
    assert_equal(
      %w[used_by_knowledge unused special general],
      Category.latest.pluck(:name)
    )
  end

  test "old orders categories by oldest created_at first" do
    assert_equal(
      %w[general special unused used_by_knowledge],
      Category.old.pluck(:name)
    )
  end

  test "name_asc orders categories by name ascending" do
    assert_equal(
      %w[general special unused used_by_knowledge],
      Category.name_asc.pluck(:name)
    )
  end

  test "name_desc orders categories by name descending" do
    assert_equal(
      %w[used_by_knowledge unused special general],
      Category.name_desc.pluck(:name)
    )
  end
end
