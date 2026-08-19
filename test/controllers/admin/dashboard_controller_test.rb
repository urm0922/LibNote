require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "cannot access admin's dashboard without sign in" do
    get admin_dashboard_index_path
    assert_redirected_to new_user_session_path
  end

  test "staff cannot access admin's dashboard" do
    sign_in users(:staff)
    get admin_dashboard_index_path

    assert_redirected_to root_path
  end

  test "manager cannot access admin's dashboard" do
    sign_in users(:manager)
    get admin_dashboard_index_path

    assert_redirected_to root_path
  end

  test "admin can access admin's dashboard" do
    sign_in users(:admin)
    get admin_dashboard_index_path

    assert_response :success
    assert_includes response.body, inquiries(:staff_answered).title
    assert_includes response.body, knowledge_articles(:staff_draft).title
  end

  test "admin's dashboard displays the number of items requiring action" do
    sign_in users(:admin)

    get admin_dashboard_index_path
    assert_response :success
    assert_select ".requiring-action-counts", text: /#{Inquiry.open.count}件の回答待ち/
    assert_select ".requiring-action-counts", text: /#{Inquiry.answered.count}件の承認待ち/
    assert_select ".requiring-action-counts", text: /#{KnowledgeArticle.draft.count}件の公開待ち/  
  end

  test "admin's dashboard dosen't display excluded inquiry and article" do
    sign_in users(:admin)

    get admin_dashboard_index_path
    assert_response :success
    assert_not_includes response.body, inquiries(:staff_draft).title
    assert_not_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:staff_approved).title
    assert_not_includes response.body, knowledge_articles(:staff_emergency_published).title
  end
end
