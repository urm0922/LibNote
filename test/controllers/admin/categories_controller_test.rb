require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles, :faq_entries
  test "admin can view category index" do
    sign_in users(:admin)
    get admin_categories_path

    assert_response :success
    assert_includes response.body, categories(:general).name
  end

  test "admin can create category" do
    sign_in users(:admin)
    assert_difference "Category.count", 1 do
      post admin_categories_path, params: {
        category: {
          name: "New category"
        }
      }
    end
  end

  test "admin can update category" do
    sign_in users(:admin)
    category = categories(:general)
    patch admin_category_path(category), params: {
      category: {
        name: "Changed_name"
      }
    }
    assert_redirected_to admin_categories_path
    assert_equal "Changed_name", category.reload.name
  end

  test "admin can destroy unused category" do
    sign_in users(:admin)
    category = categories(:unused)

    assert_difference "Category.count", -1 do
      delete admin_category_path(category)
    end
    assert_redirected_to admin_categories_path

    get admin_categories_path
    assert_not_includes response.body, category.name
  end

  test "admin cannot destroy used category" do
    sign_in users(:admin)
    category = categories(:general)

    assert_no_difference "Category.count" do
      delete admin_category_path(category)
    end

    assert_redirected_to admin_categories_path

    get admin_categories_path
    assert_includes response.body, category.name
  end

  test "admin cannot category without name" do
    sign_in users(:admin)
    assert_no_difference "Category.count" do
      post admin_categories_path, params: {
        category: {
          name: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "admin cannot duplicate category" do
    sign_in users(:admin)
    assert_no_difference "Category.count" do
      post admin_categories_path, params: {
        category: {
          name: "general"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "staff cannot access category index" do
    sign_in users(:staff)
    get admin_categories_path

    assert_redirected_to root_path
  end

  test "staff cannot create category" do
    sign_in users(:staff)
    assert_no_difference "Category.count" do
      post admin_categories_path, params: {
        category: {
          name: "New category"
        }
      }
    end
    assert_redirected_to root_path
  end

  test "staff cannot update category" do
    sign_in users(:staff)
    category = categories(:general)
    patch admin_category_path(category), params: {
      category: {
        name: "Changed_name"
      }
    }
    assert_redirected_to root_path
    assert_equal "general", category.reload.name
  end

  test "staff cannot destroy category" do
    sign_in users(:staff)
    category = categories(:unused)
    assert_no_difference "Category.count" do
      delete admin_category_path(category)
    end

    assert_redirected_to root_path
  end

  test "admin can search category by keyword" do
    sign_in users(:admin)
    get admin_categories_path, params: { q: "general" }
    assert_includes response.body, categories(:general).name
    assert_not_includes response.body, categories(:unused).name
  end

  test "admin can sort categories by name and created at" do
    sign_in users(:admin)

    get admin_categories_path, params: { sort: "latest" }
    displayed_names =
      css_select(".category-card h2").map { |element| element.text.strip }

    assert_equal(
      %w[used_by_knowledge unused special general],
      displayed_names
    )

    get admin_categories_path, params: { sort: "old" }
    displayed_names =
      css_select(".category-card h2").map { |element| element.text.strip }
    
    assert_equal(
      %w[general special unused used_by_knowledge],
      displayed_names
    )

    get admin_categories_path, params: { sort: "name_asc" }
    displayed_names =
      css_select(".category-card h2").map { |element| element.text.strip }
    
    assert_equal(
      %w[general special unused used_by_knowledge],
      displayed_names
    )

    get admin_categories_path, params: { sort: "name_desc" }
    displayed_names =
      css_select(".category-card h2").map { |element| element.text.strip }
    
    assert_equal(
      %w[used_by_knowledge unused special general],
      displayed_names
    ) 
  end

  test "Show the number of items associated with a category" do
    sign_in users(:admin)
    category = categories(:general)
    get admin_categories_path

    assert_includes response.body, category.knowledge_articles.count.to_s
    assert_includes response.body, category.inquiries.count.to_s
  end

  test "Check devided by pages" do
    sign_in users(:admin)

    # fixtureの4件と合わせて11件にする
    7.times do |i|
    Category.create!(name: "pagination_category_#{i}")
    end

    get admin_categories_path
    assert_response :success
    assert_select 'nav.pagination'
    assert_select ".category-card", count: 10

    get admin_categories_path, params: { page: 2 }

    assert_select ".category-card", count: 1
  end
end
