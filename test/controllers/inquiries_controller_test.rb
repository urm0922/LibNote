require "test_helper"
require "minitest/mock"

class InquiriesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles
  FakeGenerator = Struct.new(:result) do
    def call(inquiry:)
      result
    end
  end

  class FailingGenerator
    def call(inquiry:)
      raise JSON::ParserError, "invalid JSON"
    end
  end

  
  test "staff cannot view another user's inquiry" do
    sign_in users(:staff)
    get inquiry_path(inquiries(:other_staff_open))
    assert_response :not_found
    
  end
  
  test "staff only sees own inquiries in index" do
    sign_in users(:staff)

    get inquiries_path

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:other_staff_open).title
  end

  test "staff cannot edit finalized own inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)
    get edit_inquiry_path(inquiries(:staff_approved))

    assert_redirected_to inquiry_path(inquiry)
  end

  test "staff cannot update finalized own inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)

    assert_no_changes -> { inquiry.reload.title } do
      patch inquiry_path(inquiry), params: {
        inquiry: {
          title: "Changed title",
          body: inquiry.body,
          category_id: inquiry.category_id
        }
      }
    end

      assert_redirected_to inquiry_path(inquiry)
  end

  test "staff cannot destroy finalized own inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)
    
    assert_no_difference "Inquiry.count" do
      delete inquiry_path(inquiry)
    end
  
    assert_redirected_to inquiry_path(inquiry)
  end

  test "manager can view another users inquiry" do
    sign_in users(:manager)
    get inquiry_path(inquiries(:staff_open))

    assert_response :success
  end

  test "manager cannot update finalized inquiry" do
    sign_in users(:manager)
    inquiry = inquiries(:staff_approved)
  
    patch inquiry_path(inquiry), params: {
      inquiry: {
        title: "Manager updated",
        body: inquiry.body,
        category_id: inquiry.category_id
        }
      }

    assert_redirected_to inquiry_path(inquiry)
    assert_not_equal "Manager updated", inquiry.reload.title

  end

  test "admin can approve any inquiry" do
    sign_in users(:admin)
    inquiry = inquiries(:staff_answered)
    
    generated_result = Ai::DraftGenerator::Result.new(
      article_title: "生成された記事タイトル",
      article_body: "生成された記事本文",
      faq_question: "生成された質問",
      faq_answer: "生成された回答"
    )

    fake_generator = FakeGenerator.new(generated_result)

    Ai::DraftGenerator.stub(
      :new,
      ->(*args, **kwargs) { fake_generator }
    ) do
      assert_difference "KnowledgeArticle.count", 1 do
        assert_difference "FaqEntry.count", 1 do
          patch approve_inquiry_path(inquiry)
        end
      end
    end

    assert_redirected_to inquiry_path(inquiry)
    assert_equal "approved", inquiry.reload.status

    knowledge_article = inquiry.knowledge_article.reload
    assert_equal "draft", knowledge_article.status
    assert_equal "生成された記事タイトル", knowledge_article.title
    assert_equal "生成された記事本文", knowledge_article.body
    
    faq_entries = knowledge_article.faq_entries.reload
    assert_equal 1, faq_entries.count
    assert_equal "draft", faq_entries.first.status
    assert_equal "生成された質問", faq_entries.first.question
    assert_equal "生成された回答", faq_entries.first.answer         
  end

  test "staff cannot see another user's inquiy in search results" do
    sign_in users(:staff)

    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:other_staff_open).title
  end

  test "manager can see another user's inquiry in search results" do
    sign_in users(:manager)
    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
  end

  test "manager does not see another user's draft in index" do
    sign_in users(:manager)

    get inquiries_path

    assert_response :success
    assert_includes response.body, inquiries(:manager_draft).title
    assert_not_includes response.body, inquiries(:staff_draft).title
  end

  test "manager cannot handle other's draft inquiry" do
    inquiry = inquiries(:staff_draft)
    sign_in users(:manager)
    get inquiry_path(inquiry)
    
    
    assert_redirected_to inquiries_path
    assert_equal "この問い合わせを閲覧する権限がありません", flash[:alert]

    patch inquiry_path(inquiry), params: {
      inquiry: {
        title: "Changed_title",
        body: "Changed_body"
      }
    }

    assert_redirected_to inquiry_path(inquiry)
    assert_not_equal "Changed_title", inquiry.reload.title
    assert_not_equal "Changed_body", inquiry.reload.body
    
    assert_no_difference "Inquiry.count" do
      delete inquiry_path(inquiry)
    end

    assert_redirected_to inquiry_path(inquiry)
  end

  test "manager can handle own draft inquiry" do
    sign_in users(:manager)
    inquiry = inquiries(:manager_draft)

    get inquiry_path(inquiry)
    
    assert_response :success
    assert_includes response.body, inquiry.reload.title

    patch inquiry_path(inquiry), params: {
      inquiry: {
        title: "Changed_title",
        body: "Changed_body"
      }
    }

    assert_redirected_to inquiry_path(inquiry)
    assert_equal "Changed_title", inquiry.reload.title
    assert_equal "Changed_body", inquiry.reload.body
    
    assert_difference "Inquiry.count", -1 do
      delete inquiry_path(inquiry)
    end

    assert_redirected_to inquiries_path
  end

  test "manager can handle other's open inquiry" do
    sign_in users(:manager)
    inquiry = inquiries(:staff_open)

    get inquiry_path(inquiry)
    
    assert_response :success
    assert_includes response.body, inquiry.reload.title

    patch inquiry_path(inquiry), params: {
      inquiry: {
        title: "Changed_title",
        body: "Changed_body"
      }
    }

    assert_redirected_to inquiry_path(inquiry)
    assert_equal "Changed_title", inquiry.reload.title
    assert_equal "Changed_body", inquiry.reload.body
    
    assert_difference "Inquiry.count", -1 do
      delete inquiry_path(inquiry)
    end

    assert_redirected_to inquiries_path
  end

  test "admin can view and update any inquiries" do
    sign_in users(:admin)
    statuses = %w[draft open answered approved rejected]

    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
      get inquiry_path(inquiry)
    
      assert_response :success
      assert_includes response.body, inquiry.reload.title, "admin should view detail on #{status} inquiry"

      patch inquiry_path(inquiry), params: {
        inquiry: {
          title: "Changed_title",
          body: "Changed_body"
        }
      }

      assert_redirected_to inquiry_path(inquiry)
      assert_equal "Changed_title", inquiry.reload.title, "admin should change title of #{status} inquiry"
      assert_equal "Changed_body", inquiry.reload.body, "admin should change body of #{status} inquiry"
    end
  end

  test "admin can destroy inquiries of non-knowledge" do
    sign_in users(:admin)
    statuses = %w[draft open answered rejected]
    statuses.each do |status|
      inquiry = inquiries(:"staff_#{status}")
      assert_difference "Inquiry.count", -1, "admin should destroy #{status} inquiry" do
        delete inquiry_path(inquiry)
      end
      assert_redirected_to inquiries_path
    end
  end

  test "admin cannot destroy inquiry linked knowledge article" do
    sign_in users(:admin)
    inquiry = inquiries(:staff_approved)

    assert_no_difference "Inquiry.count" do
      delete inquiry_path(inquiry)
    end

    assert Inquiry.exists?(inquiry.id)
    assert_redirected_to inquiry_path(inquiry)
  end

  test "admin can see another user's inquiry in search results" do
    sign_in users(:admin)
    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
  end

  test "admin does not see another user's draft in index" do
    sign_in users(:admin)

    get inquiries_path

    assert_response :success
    assert_includes response.body, inquiries(:admin_draft).title
    assert_not_includes response.body, inquiries(:staff_draft).title
  end

  test "admin can directly access another user's draft" do
    sign_in users(:admin)
    inquiry = inquiries(:staff_draft)

    get inquiry_path(inquiry)

    assert_response :success
    assert_includes response.body, inquiry.title
  end

  test "staff can search by keyword" do
    sign_in users(:staff)
    get inquiries_path, params: { q: "open" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_open).title
    assert_not_includes response.body, inquiries(:staff_approved).title
  end

  test "staff can search by category" do
    sign_in users(:staff)
    get inquiries_path, params: { category_id: categories(:special).id }

    assert_response :success
    assert_includes response.body, inquiries(:staff_special).title
    assert_not_includes response.body, inquiries(:staff_open).title
  end

  test "staff can search by status" do
    sign_in users(:staff)
    get inquiries_path, params: { status: "approved" }

    assert_response :success
    assert_includes response.body, inquiries(:staff_approved).title
    assert_not_includes response.body, inquiries(:staff_open).title
  end

  test "staff cannot update answered inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_answered)

    assert_no_changes -> { inquiry.reload.title} do
      assert_no_changes -> {inquiry.reload.status} do
        patch inquiry_path(inquiry), params: {
          inquiry: {
            title: "Changed title",
            body: inquiry.body,
            category_id: inquiry.category_id,
            status: "approved"
          }
        }
      end
    end
  end

  test "staff cannot update rejected inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_rejected)

    assert_no_changes -> { inquiry.reload.title } do
      assert_no_changes -> {inquiry.reload.status } do
        patch inquiry_path(inquiry), params: {
          inquiry: {
            title: "Changed title",
            body: inquiry.body,
            category_id: inquiry.category_id,
            status: "approved"
          }
        }
      end
    end
  end
  
  test "staff cannot update inquiry with blank status" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_draft)
    assert_no_changes -> { inquiry.reload.title } do
      patch inquiry_path(inquiry), params: {
          inquiry: {
          title: "Changed title",
          body: inquiry.body,
          category_id: inquiry.category_id,
          status: ""
          }
      }
    end
  end

  test "staff cannot create inquiry with invalid status" do
    sign_in users(:staff)
    assert_no_difference "Inquiry.count" do
      post inquiries_path, params: {
        inquiry: {
          title: "Bad status",
          body: "body",
          category_id: categories(:general).id,
          status: "approved"
        }
      }
    end
  end

  test "approval won't be performed when generation error occurs" do
    sign_in users(:admin)
    inquiry = inquiries(:staff_answered)
    failing_generator = FailingGenerator.new

    Ai::DraftGenerator.stub(
      :new,
      ->(*args, **kwargs) { failing_generator }
    ) do
      assert_no_difference ["KnowledgeArticle.count", "FaqEntry.count"] do
        patch approve_inquiry_path(inquiry)
      end
    end

    assert_redirected_to inquiry_path(inquiry)
    assert_equal "answered", inquiry.reload.status
    assert_equal(
      "AIによる下書き生成に失敗しました。時間をおいて再度お試しください",
      flash[:alert]
    )
  end

  test "already approved inquiry is not approved again" do
    sign_in users(:admin)
    inquiry = inquiries(:staff_approved)

    generated_result = Ai::DraftGenerator::Result.new(
      article_title: "生成された記事タイトル",
      article_body: "生成された記事本文",
      faq_question: "生成された質問",
      faq_answer: "生成された回答"
    )

    fake_generator = FakeGenerator.new(generated_result)

    Ai::DraftGenerator.stub(
      :new,
      ->(*args, **kwargs) { fake_generator }
    ) do
  
      assert_no_difference ["KnowledgeArticle.count", "FaqEntry.count"] do
        patch approve_inquiry_path(inquiry)
      end
    
      assert_redirected_to inquiry_path(inquiry)
      assert_equal(
        "この問い合わせはすでに承認されています",
        flash[:alert]
      )
      assert_equal "approved", inquiry.reload.status

      
    end
  end

  test "staff can post inquiry attached images" do
    sign_in users(:staff)
    image = fixture_file_upload("sample1.png", "image/png")

    assert_difference ["Inquiry.count", "ActiveStorage::Attachment.count"], 1 do
      post inquiries_path, params: {
        inquiry: {
          title: "inquiry_image",
          body: "body",
          category_id: categories(:general).id,
          status: "open",
          images: [image]
        }
      }
    end
    
    inquiry = Inquiry.order(:id).last

    assert inquiry.images.attached?
    assert_equal "sample1.png", inquiry.images.first.filename.to_s
    assert_equal "image/png", inquiry.images.first.content_type
  end

  test "staff can view the attached images on inquiry detail page" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_open)

    inquiry.images.attach(
      io: File.open(file_fixture("sample1.png")),
      filename: "sample1.png",
      content_type: "image/png"
    )

    get inquiry_path(inquiry)

    assert_response :success
    assert_select "img.inquiry-image[alt='問い合わせ添付画像']", count: 1
  end

  test "staff cannot post inquiry attached 4 or more images" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_open)

    images = 4.times.map do |i|
      fixture_file_upload(
        "sample#{i + 1}.png",
        "image/png"
      )
    end

    assert_no_difference ["Inquiry.count", "ActiveStorage::Attachment.count"] do
      post inquiries_path, params: {
        inquiry: {
          title: "画像が多すぎる問い合わせ",
          body: "本文",
          category_id: categories(:general).id,
          status: "open",
          images: images
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "3枚までしか投稿できません"

    inquiry = inquiries(:staff_open)

    assert_no_difference "ActiveStorage::Attachment.count" do
      patch inquiry_path(inquiry), params: {
        inquiry: {
          title: inquiry.title,
          body: inquiry.body,
          category_id: inquiry.category_id,
          status: inquiry.status,
          images: images
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "3枚までしか投稿できません"
  end

  test "staff can view multiple images on index and detail" do
    sign_in users(:staff)

    images = 3.times.map do |i|
      fixture_file_upload(
        "sample#{i + 1}.png",
        "image/png"
      )
    end

    post inquiries_path, params: {
        inquiry: {
          title: "3枚の画像の問い合わせ",
          body: "本文",
          category_id: categories(:general).id,
          status: "open",
          images: images
        }
      }
    inquiry = Inquiry.order(:id).last

    assert_redirected_to inquiry_path(inquiry)
    get inquiry_path(inquiry)
    assert_select "img.inquiry-image[alt='問い合わせ添付画像']", count: 3

    get inquiries_path
    assert_select "img.inquiry-image[alt='問い合わせ添付画像']", count: 3
  end

  test "staff can view inquiry detail without image" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_open)
    get inquiry_path(inquiry)

    assert_response :success
    assert_includes response.body, inquiry.title
  end

end