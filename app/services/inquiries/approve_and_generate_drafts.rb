class Inquiries::ApproveAndGenerateDrafts
    def initialize(inquiry:, approver:, generator: Ai::DraftGenerator.new)
      @inquiry = inquiry
      @approver = approver
      @generator = generator
    end
  
    def call
      generated = generator.call(inquiry: inquiry)

      ActiveRecord::Base.transaction do
        inquiry.update!(status: :approved,
                        approver: approver,
                        approved_at: Time.current)

        knowledge_article = inquiry.create_knowledge_article!(
          category: inquiry.category,
          author: inquiry.user,
          title: generated.article_title,
          body: generated.article_body,
          status: :draft,
          generated_by_ai: true
        )

        knowledge_article.faq_entries.create!(
          question: generated.faq_question,
          answer: generated.faq_answer,
          status: :draft,
          generated_by_ai: true
        )
      end 
    end


  
    private
  
    attr_reader :inquiry, :approver, :generator
  end