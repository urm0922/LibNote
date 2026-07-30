require "test_helper"

class Admin::BaseControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles, :faq_entries
  test "user before log in cannot access management portal" do
    get admin_categories_path
    assert_redirected_to new_user_session_path
  end

  test "manager cannot access management potal" do
    sign_in users(:manager)
    get admin_categories_path
    assert_redirected_to root_path
  end

  test "staff cannot view management link" do
    sign_in users(:staff)
    get root_path

    assert_select "a[href=?]", admin_categories_path, count: 0
  end
  
  test "manager can view management link" do
    sign_in users(:manager)
    get root_path

    assert_select "a[href=?]", admin_categories_path, count: 0
  end
  
  test "admin can view management link" do
    sign_in users(:admin)
    get root_path

    assert_select "a[href=?]", admin_categories_path, count: 1
  end

end
