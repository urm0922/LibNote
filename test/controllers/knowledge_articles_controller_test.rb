require "test_helper"

class KnowledgeArticlesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles

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
end
