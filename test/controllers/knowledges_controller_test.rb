require "test_helper"

class KnowledgesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments

  test "staff can view only approved knowledge" do
    sign_in users(:staff)
    get knowledges_path

    assert_response :success
    assert_includes response.body, inquiries(:staff_approved).title
    assert_not_includes response.body, inquiries(:staff_draft).title
    assert_not_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:staff_answered).title
    assert_not_includes response.body, inquiries(:staff_rejected).title
  end

  test "staff can view approved knowledge detail" do
    sign_in users(:staff)

    get knowledge_path(inquiries(:staff_approved))

    assert_response :success
    assert_includes response.body, inquiries(:staff_approved).title
  end

  test "staff cannot view unapproved knowledge detail" do
    sign_in users(:staff)
  
    get knowledge_path(inquiries(:staff_answered))
  
    assert_response :not_found
    
  end
end
