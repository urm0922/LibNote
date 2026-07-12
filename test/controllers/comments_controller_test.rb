require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  test "staff cannot destroy other user's comments" do
    sign_in users(:manager)
    inquiry = (:staff_open)
    post inquiry_comments_path(inquiry), params: {
      comments: { body: inquiry.body }}
    
    sign_out users(:manager)
    sign_in users(:staff)
    assert_no_changes 

end
