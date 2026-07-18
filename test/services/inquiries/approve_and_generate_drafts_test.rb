require "test_helper"

class Inquiries::ApproveAndGenerateDraftsTest < ActiveSupport::TestCase
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles
  test "approves inquiry and generates drafts" do
    inquiry = inquiries(:staff_answered)
    approver = users(:admin)

    assert_difference ["KnowledgeArticle.count", "FaqEntry.count"],1 do
        Inquiries::ApproveAndGenerateDrafts.new(
            inquiry: inquiry,
            approver: approver
          ).call
    end

    assert_equal "approved", inquiry.reload.status

    knowledge_article = inquiry.knowledge_article.reload
    faq_entry = knowledge_article.faq_entries.reload.first
    
    assert_equal "draft", knowledge_article.reload.status
    assert_equal inquiry.title, knowledge_article.title
    assert_equal inquiry.body, knowledge_article.body
    assert_not knowledge_article.published_at?
    assert_equal inquiry.user, knowledge_article.author
    assert_not knowledge_article.generated_by_ai?

    assert_equal "draft", faq_entry.reload.status
    assert_equal inquiry.title, faq_entry.question
    assert_equal inquiry.body, faq_entry.answer
    assert_not faq_entry.generated_by_ai?
  end

  test "records the approver when approving an inquiry" do
    inquiry = inquiries(:staff_answered)
    approver = users(:admin)
  
    Inquiries::ApproveAndGenerateDrafts.new(
      inquiry: inquiry,
      approver: approver
    ).call

    inquiry.reload
 
    assert inquiry.approved?
    assert_equal approver, inquiry.approver
    assert_not_nil inquiry.approved_at
  end


    

end