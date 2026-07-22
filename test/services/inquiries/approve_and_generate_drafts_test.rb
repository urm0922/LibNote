require "test_helper"

class Inquiries::ApproveAndGenerateDraftsTest < ActiveSupport::TestCase
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles
  FakeGenerator = Struct.new(:result) do
    def call(inquiry:)
      result
    end
  end
  
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
    assert knowledge_article.generated_by_ai?

    assert_equal "draft", faq_entry.reload.status
    assert_equal inquiry.title, faq_entry.question
    assert_equal inquiry.body, faq_entry.answer
    assert faq_entry.generated_by_ai?
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

  test "saves the result returned by the generator" do
    inquiry = inquiries(:staff_answered)
    approver = users(:admin)

    Inquiries::ApproveAndGenerateDrafts.new(
      inquiry: inquiry,
      approver: approver,
      generator: fake_generator
    ).call
    
    knowledge_article = inquiry.reload.knowledge_article
    faq_entry = knowledge_article.faq_entries.first

    assert_equal "AIが生成した記事タイトル", knowledge_article.title
    assert_equal "AIが生成した記事本文", knowledge_article.body
    assert_equal "AIが生成した質問", faq_entry.question
    assert_equal "AIが生成した回答", faq_entry.answer
    
    
  end

  private

  def generated_result
    Ai::DraftGenerator::Result.new(
      article_title: "AIが生成した記事タイトル",
      article_body: "AIが生成した記事本文",
      faq_question: "AIが生成した質問",
      faq_answer: "AIが生成した回答"
    )
  end

  def fake_generator
    FakeGenerator.new(generated_result)
  end
end