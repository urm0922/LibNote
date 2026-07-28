require "test_helper"

class FaqEntriesControllerTest < ActionDispatch::IntegrationTest
  test "staff can view only faq published and enabled" do
    sign_in users(:staff)
    get faq_entries_path

    assert_includes response.body, faq_entries(:staff_published_faq).question
    assert_not_includes response.body, faq_entries(:other_draft_faq).question
    assert_not_includes response.body, faq_entries(:other_published_false_faq).question
  end
end
