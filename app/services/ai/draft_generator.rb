class Ai::DraftGenerator
  OUTPUT_SCHEMA = {
    type: "object",
    properties: {
      article_title: { type: "string" },
      article_body: { type: "string" },
      faq_question: { type: "string" },
      faq_answer: { type: "string" }
    },
    required: %w[
      article_title
      article_body
      faq_question
      faq_answer
    ],
    additionalProperties: false
  }.freeze

  Result = Data.define(
    :article_title,
    :article_body,
    :faq_question,
    :faq_answer
  )

  def initialize(
    client: OpenAI::Client.new,
    model: ENV.fetch("OPENAI_MODEL", "gpt-5.6-terra")
  )
    @client = client
    @model = model
  end

  def call(inquiry:)
    response = client.responses.create(
      model: model,
      input: build_input(inquiry),
      text: {
        format: {
          type: :json_schema,
          name: "draft",
          strict: true,
          schema: OUTPUT_SCHEMA
        }
      }
    )

    attributes = JSON.parse(
      response.output_text,
      symbolize_names: true
    )

    Result.new(
      article_title: attributes[:article_title],
      article_body: attributes[:article_body],
      faq_question: attributes[:faq_question],
      faq_answer: attributes[:faq_answer]
    )
  end

  private

  attr_reader :client, :model

  def build_input(inquiry)
    [
      {
        role: :system,
        content: <<~TEXT
          あなたは図書館業務のナレッジ作成担当者です。
          問い合わせ内容をもとに記事とFAQを作成してください。
        TEXT
      },
      {
        role: :user,
        content: <<~TEXT
          問い合わせタイトル：
          #{inquiry.title}

          問い合わせ本文：
          #{inquiry.body}
        TEXT
      }
    ]
      
  end
end