class Inquiries::ApproveAndGenerateDrafts
    def initialize(inquiry:, approver:)
      @inquiry = inquiry
      @approver = approver
    end
  
    def call
      ActiveRecord::Base.transaction do
        inquiry.update!(status: :approved,
                        approver: approver,
                        approved_at: Time.current)

        knowledge_article = inquiry.create_knowledge_article!(
          category: inquiry.category,
          author: inquiry.user,
          title: inquiry.title,
          body: inquiry.body,
          status: :draft,
          generated_by_ai: false
        )

        knowledge_article.faq_entries.create!(
          question: inquiry.title,
          answer: inquiry.body,
          status: :draft,
          generated_by_ai: false
        )
      end 
    end


  
    private
  
    attr_reader :inquiry, :approver
  end