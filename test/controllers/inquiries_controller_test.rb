require "test_helper"

class InquiriesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments
  
  test "staff cannot view another user's inquiry" do
    sign_in users(:staff)
    get inquiry_path(inquiries(:other_staff_open))
    assert_response :not_found
    
  end
  
  test "staff only sees own inquiries in index" do
    sign_in users(:staff)

    get inquiries_path

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:other_staff_open).title
  end

  test "staff cannot edit finalized own inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)
    get edit_inquiry_path(inquiries(:staff_approved))

    assert_redirected_to inquiry_path(inquiry)
  end

  test "staff cannot update finalized own inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)

    assert_no_changes -> { inquiry.reload.title } do
      patch inquiry_path(inquiry), params: {
        inquiry: {
          title: "Changed title",
          body: inquiry.body,
          category_id: inquiry.category_id
        }
      }
    end

      assert_redirected_to inquiry_path(inquiry)
  end

  test "staff cannot destroy finalized own inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)
    
    assert_no_difference "Inquiry.count" do
      delete inquiry_path(inquiry)
    end
  
    assert_redirected_to inquiry_path(inquiry)
  end

  test "manager can view another users inquiry" do
    sign_in users(:manager)
    get inquiry_path(inquiries(:staff_open))

    assert_response :success
  end

  test "manager cannot update finalized inquiry" do
    sign_in users(:manager)
    inquiry = inquiries(:staff_approved)
  
    patch inquiry_path(inquiry), params: {
      inquiry: {
        title: "Manager updated",
        body: inquiry.body,
        category_id: inquiry.category_id
        }
      }

    assert_redirected_to inquiry_path(inquiry)
    assert_not_equal "Manager updated", inquiry.reload.title

  end

  test "admin can approve any inquiry" do
    sign_in users(:admin)
    inquiry = inquiries(:staff_answered)

    patch approve_inquiry_path(inquiry)

    assert_redirected_to inquiry_path(inquiry)
    assert_equal "approved", inquiry.reload.status
  end

  test "staff cannot see another user's inquiy in search results" do
    sign_in users(:staff)

    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:other_staff_open).title
  end

  test "manager can see another user's inquiry in search results" do
    sign_in users(:manager)
    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
  end

  test "manager does not see another user's draft in index" do
    sign_in users(:manager)

    get inquiries_path

    assert_response :success
    assert_includes response.body, inquiries(:manager_draft).title
    assert_not_includes response.body, inquiries(:staff_draft).title
  end

  test "admin can see another user's inquiry in search results" do
    sign_in users(:admin)
    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
  end

  test "admin does not see another user's draft in index" do
    sign_in users(:admin)

    get inquiries_path

    assert_response :success
    assert_includes response.body, inquiries(:admin_draft).title
    assert_not_includes response.body, inquiries(:staff_draft).title
  end

  test "staff can search by keyword" do
    sign_in users(:staff)
    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:staff_approved).title
  end

  test "staff can search by category" do
    sign_in users(:staff)
    get inquiries_path, params: { category_id: categories(:special).id }

    assert_response :success
    assert_includes response.body, inquiries(:staff_special).title
    assert_not_includes response.body, inquiries(:staff_open).title
  end

  test "staff can search by status" do
    sign_in users(:staff)
    get inquiries_path, params: { status: "approved" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_approved).title
    assert_not_includes response.body, inquiries(:staff_open).title
  end

  test "staff cannot update answered inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_answered)

    assert_no_changes -> { inquiry.reload.title} do
      assert_no_changes -> {inquiry.reload.status} do
        patch inquiry_path(inquiry), params: {
          inquiry: {
            title: "Changed title",
            body: inquiry.body,
            category_id: inquiry.category_id,
            status: "approved"
          }
        }
      end
    end
  end

  test "staff cannot update rejected inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_rejected)

    assert_no_changes -> { inquiry.reload.title } do
      assert_no_changes -> {inquiry.reload.status } do
        patch inquiry_path(inquiry), params: {
          inquiry: {
            title: "Changed title",
            body: inquiry.body,
            category_id: inquiry.category_id,
            status: "approved"
          }
        }
      end
    end
  end
  
  test "staff cannot update inquiry with blank status" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_draft)
    assert_no_changes -> { inquiry.reload.title } do
      patch inquiry_path(inquiry), params: {
          inquiry: {
          title: "Changed title",
          body: inquiry.body,
          category_id: inquiry.category_id,
          status: ""
          }
      }
    end
  end

  test "staff cannot create inquiry with invalid status" do
    sign_in users(:staff)
    assert_no_difference "Inquiry.count" do
      post inquiries_path, params: {
        inquiry: {
          title: "Bad status",
          body: "body",
          category_id: categories(:general).id,
          status: "approved"
        }
      }
    end
  end

end