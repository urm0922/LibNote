class Inquiries::ApproveAndGenerateDrafts
  class GenerationError < StandardError; end
  class AlreadyApprovedError < StandardError; end

  def initialize(inquiry:, approver:, generator: Ai::DraftGenerator.new)
    @inquiry = inquiry
    @approver = approver
    @generator = generator
  end
    
  
  
    def call
      raise AlreadyApprovedError if inquiry.reload.approved?

      # 外部APIの応答待ちでは行ロックを保持せず、生成中の競合はロック取得後の再確認で防ぐ。
      generated = generator.call(inquiry: inquiry)

      ActiveRecord::Base.transaction do
        inquiry.lock!

        raise AlreadyApprovedError if inquiry.approved?
        
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

      rescue OpenAI::Errors::Error, JSON::ParserError => error
        Rails.logger.error(
          "AI draft generation failed: inquiry_id=#{inquiry.id} " \
          "error=#{error.class}"
        )
    
        raise GenerationError, "AI draft generation failed" 
     end
    


  
    private
  
    attr_reader :inquiry, :approver, :generator
  end
