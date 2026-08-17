require "test_helper"

class FaqEntriesControllerTest < ActionDispatch::IntegrationTest
  test "staff can view only faq published and enabled" do
    sign_in users(:staff)
    get faq_entries_path

    assert_includes response.body, faq_entries(:staff_published_faq).question
    assert_not_includes response.body, faq_entries(:other_draft_faq).question
    assert_not_includes response.body, faq_entries(:other_published_false_faq).question
  end

  test "staff can search by category" do
    sign_in users(:staff)
    get faq_entries_path

    assert_response :success
    assert_includes response.body, faq_entries(:staff_published_faq).reload.question
    assert_includes response.body, faq_entries(:staff_emergency_published_faq).reload.question

    get faq_entries_path, params: {
      category_id: categories(:special).id
    }

    assert_response :success
    assert_not_includes response.body, faq_entries(:staff_published_faq).reload.question
    assert_includes response.body, faq_entries(:staff_emergency_published_faq).reload.question

  end
end
