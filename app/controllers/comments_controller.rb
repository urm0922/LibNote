class CommentsController < ApplicationController
  before_action :authenticate_user!
  def create
    inquiry = Inquiry.find(params[:inquiry_id])
    comment = Comment.new(comment_params)
    comment.user_id = current_user.id
    comment.inquiry_id = inquiry.id
    if comment.save
      redirect_to inquiry_path(inquiry), notice: "コメントを作成しました"
    else
      redirect_to inquiry_path(inquiry), alert: "コメント作成に失敗しました"
    end
  end

  def destroy
    Comment.find_by(id: params[:id], inquiry_id: params[:inquiry_id], user_id: current_user.id).destroy
    redirect_to inquiry_path(inquiry), notice: "コメントを削除しました"
  end

  private
  
  def comment_params
    params.require(:comment).permit(:body)
  end

end
