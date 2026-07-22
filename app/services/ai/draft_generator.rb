class Ai::DraftGenerator
  Result = Data.define(
    :article_title,
    :article_body,
    :faq_question,
    :faq_answer
  )

  def call(inquiry:)
    # 後ほどここで生成AIを呼ぶ
    Result.new(
      article_title: inquiry.title,
      article_body: inquiry.body,
      faq_question: inquiry.title,
      faq_answer: inquiry.body
    )
  end
end