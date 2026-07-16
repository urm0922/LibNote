require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :inquiries, :categories, :comments, :knowledge_articles

  test "staff cannot destroy comments in approved inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)
    
    assert_no_difference "Comment.count" do
      delete inquiry_comment_path(inquiry, comments(:comment_as_staff_approved))
    end

    assert_redirected_to inquiry_path(inquiry)
  end

  test "staff cannot create comment in approved inquiry" do
    sign_in users(:staff)
    inquiry = inquiries(:staff_approved)

    assert_no_difference "Comment.count" do
      post inquiry_comments_path(inquiry), params: { 
        comment: {
          body: "cannot create comment"
        }
      }
    end

    assert_redirected_to inquiry_path(inquiry)
  end

end
