require "test_helper"

class FaqEntryTest < ActiveSupport::TestCase
  test "publicly_visible returns only publishable faq entries" do
    faq_entries = FaqEntry.publicly_visible
  
    assert_includes faq_entries, faq_entries(:staff_published_faq)
    assert_not_includes faq_entries, faq_entries(:other_draft_faq)
    assert_not_includes faq_entries, faq_entries(:other_published_false_faq)
  end
end
