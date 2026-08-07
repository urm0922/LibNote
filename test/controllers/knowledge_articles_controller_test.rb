require "test_helper"

class KnowledgeArticlesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles, "active_storage/blobs", "active_storage/attachments"

  test "staff can view only published knowledge articles " do
    sign_in users(:staff)
    get knowledge_articles_path

    assert_response :success
    assert_includes response.body, knowledge_articles(:other_staff_published).title
    assert_not_includes response.body, knowledge_articles(:staff_draft).title
  end

  test "staff can view published knowledge article detail" do
    sign_in users(:staff)

    get knowledge_article_path(knowledge_articles(:other_staff_published))

    assert_response :success
    assert_includes response.body, knowledge_articles(:other_staff_published).title
  end

  test "staff cannot view unpublished knowledge articles detail" do
    sign_in users(:staff)
  
    get knowledge_article_path(knowledge_articles(:staff_draft))
  
    assert_response :not_found
    
  end

  test "staff cannot edit knowledge article" do
    sign_in users(:staff)

    get edit_knowledge_article_path(knowledge_articles(:other_staff_published))

    assert_redirected_to knowledge_articles_path
  end

  test "admin can edit knowledge article" do
    sign_in users(:admin)

    get edit_knowledge_article_path(knowledge_articles(:other_staff_published))

    assert_response :success
  end

  test "admin can update knowledge article" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:other_staff_published)

    patch knowledge_article_path(knowledge_article), params: {
      knowledge_article: {
        title: "updated knowledge",
        body: knowledge_article.body,
        category_id: knowledge_article.category_id,
        status: knowledge_article.status,
        published_at: knowledge_article.published_at
      }
    }

    assert_redirected_to knowledge_article_path(knowledge_article)
    assert_equal "updated knowledge", knowledge_article.reload.title
  end

  test "admin can destroy knowledge article" do
    sign_in users(:admin)

    assert_difference "KnowledgeArticle.count", -1 do
      delete knowledge_article_path(knowledge_articles(:staff_draft))
    end

    assert_redirected_to knowledge_articles_path
  end
  
  test "staff cannot view draft knowledge articles" do
    sign_in users(:staff)
    get drafts_knowledge_articles_path

    assert_redirected_to knowledge_articles_path

  end

  test "admin can view draft knowledge articles" do
    sign_in users(:admin)
    get drafts_knowledge_articles_path
    
    assert_includes response.body, knowledge_articles(:staff_draft).title
    assert_not_includes response.body, knowledge_articles(:other_staff_published).title
  end

  test "publish only knowledge article without faq enabled" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:staff_draft)

    patch publish_knowledge_article_path(knowledge_article)

    assert_equal "published", knowledge_article.reload.status
    assert_equal "draft", knowledge_article.faq_entries.first.reload.status
  end

  test "publish knowledge article and faq entry if faq enabled" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:other_staff_draft)

    patch publish_knowledge_article_path(knowledge_article)

    assert_equal "published", knowledge_article.reload.status
    assert_equal "published", knowledge_article.faq_entries.first.reload.status
  end

  test "admin can view draft knowledge articles in drafts" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:staff_draft)
    get drafts_knowledge_articles_path
    

    assert_includes response.body, knowledge_article.title
    assert_includes response.body, knowledge_article.body
    assert_not_includes response.body, knowledge_articles(:other_staff_published).title
    assert_not_includes response.body, knowledge_articles(:other_staff_published).body

  end

  test "admin can view draft knowledge article show" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:staff_draft)
    get knowledge_article_path(knowledge_article)

    assert_includes response.body, knowledge_article.title
    assert_includes response.body, knowledge_article.body
  end

  test "staff cannot publish draft knowledge_article" do
    sign_in users(:staff)
    knowledge_article = knowledge_articles(:staff_draft)
    patch publish_knowledge_article_path(knowledge_article)

    assert_redirected_to knowledge_articles_path
    assert_equal "draft", knowledge_article.reload.status
  end

  test "published datetime are also recorded when knowledge article is published " do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:other_staff_draft)

    patch publish_knowledge_article_path(knowledge_article)
    
    assert knowledge_article.reload.published_at?
    assert knowledge_article.faq_entries.first.reload.published_at?
  end

  test "cannot publish by update" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:staff_draft)

    put knowledge_article_path(knowledge_article), params: { 
      knowledge_article: {
        status: :published 
      }
    }

    assert_equal "draft", knowledge_article.reload.status
  end

  test "admin can publish knowledge article and faq entry at the same time" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:other_staff_draft)

    patch publish_knowledge_article_path(knowledge_article)

    assert_equal "published", knowledge_article.reload.status
    assert_equal "published", knowledge_article.faq_entries.first.reload.status
  end
  
  test "published knowledge article displays inquiry image" do
    sign_in users(:staff)
    knowledge_article = knowledge_articles(:other_staff_published)

    assert knowledge_article.inquiry.images.attached?

    get knowledge_articles_path

    assert_response :success
    assert_select "img.knowledge_article-image[alt='ナレッジ添付画像']",count: 1

    get knowledge_article_path(knowledge_article)

    assert_response :success
    assert_select "img.knowledge_article-image[alt='ナレッジ添付画像']",count: 1
  end

  test "faq entry turns draft when faq_enabled switched false in published knowledge article" do
    knowledge_article = knowledge_articles(:staff_published)
    sign_in users(:admin)
    faq_entry = knowledge_article.faq_entries.first

    assert knowledge_article.faq_enabled?
    assert faq_entry.published?

    patch knowledge_article_path(knowledge_article), params: {
      knowledge_article: {
        faq_enabled: false
      }
    }
    assert_redirected_to knowledge_article_path(knowledge_article)
    assert_not knowledge_article.reload.faq_enabled?
    assert_equal "draft", faq_entry.reload.status
  end

  test "faq entry sync with the article's status when faq enabled switched true" do
    knowledge_article = knowledge_articles(:other_staff_published)
    sign_in users(:admin)
    faq_entry = knowledge_article.faq_entries.first

    assert_not knowledge_article.faq_enabled?
    assert_equal "draft", faq_entry.status
    assert_equal "published", knowledge_article.status

    patch knowledge_article_path(knowledge_article), params: {
      knowledge_article: {
        faq_enabled: true
      }
    }

    assert_redirected_to knowledge_article_path(knowledge_article)
    assert_equal "published", faq_entry.reload.status
    assert_equal faq_entry.reload.status, knowledge_article.reload.status
  end

  test "published date will not changed if changed only title" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:staff_published)
    faq_entry = knowledge_article.faq_entries.first
    original_published_at = faq_entry.published_at

    patch knowledge_article_path(knowledge_article), params: {
      knowledge_article: {
        title: "Changed_title"
      }
    }
    assert_redirected_to knowledge_article_path(knowledge_article)
    assert_equal "Changed_title", knowledge_article.reload.title
    assert_equal original_published_at, faq_entry.reload.published_at
  end

  test "faq entry turns draft when knowledge_article turns draft" do
    sign_in users(:admin)
    knowledge_article = knowledge_articles(:staff_published)
    faq_entry = knowledge_article.faq_entries.first
    assert_equal "published", knowledge_article.reload.status
    assert_equal "published", faq_entry.status
    
    patch draft_knowledge_article_path(knowledge_article)
    
    assert_redirected_to knowledge_article_path(knowledge_article)
    assert_equal "draft", knowledge_article.reload.status
    assert_equal "draft", faq_entry.reload.status
  end








end

