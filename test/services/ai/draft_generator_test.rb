require "test_helper"

class Ai::DraftGeneratorTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:output_text)

  class FakeResponses
    attr_reader :received_params

    def initialize(output_text)
      @output_text = output_text
    end

    def create(**params)
      @received_params = params
      FakeResponse.new(@output_text)
    end
  end

  FakeClient = Struct.new(:responses)

  
  test "returns article and FAQ drafts generated from an inquiry" do
    inquiry = inquiries(:staff_answered)
    
    output_text = {
      article_title: "生成された記事タイトル",
      article_body: "生成された記事本文",
      faq_question: "生成された質問",
      faq_answer: "生成された回答"
    }.to_json

    fake_responses = FakeResponses.new(output_text)
    fake_client = FakeClient.new(fake_responses)

    generator = Ai::DraftGenerator.new(
      client: fake_client,
      model: "test-model"
    )

    generated = generator.call(inquiry: inquiry)
  
    assert_equal "生成された記事タイトル", generated.article_title
    assert_equal "生成された記事本文", generated.article_body
    assert_equal "生成された質問", generated.faq_question
    assert_equal "生成された回答", generated.faq_answer
  end
  
  
end