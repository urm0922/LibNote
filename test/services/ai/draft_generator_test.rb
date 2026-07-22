require "test_helper"

class Ai::DraftGeneratorTest < ActiveSupport::TestCase
  test "returns article and FAQ drafts generated from an inquiry" do
    inquiry = inquiries(:staff_answered)
    generator = Ai::DraftGenerator.new

    generated = generator.call(inquiry: inquiry)
  
    assert_equal inquiry.title, generated.article_title
    assert_equal inquiry.body, generated.article_body
    assert_equal inquiry.title, generated.faq_question
    assert_equal inquiry.body, generated.faq_answer
  end  
end