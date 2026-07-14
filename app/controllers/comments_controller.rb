class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry

  def create
    comment = @inquiry.comments.new(comment_params)
    comment.user_id = current_user.id
    
    if comment.inquiry.status.in?(can_comment)
    
      if comment.save
        redirect_to inquiry_path(@inquiry), notice: "コメントを作成しました"
      else
        redirect_to inquiry_path(@inquiry), alert: "コメント作成に失敗しました"
      end
    else
      redirect_to inquiry_path(@inquiry), alert: "コメントを作成に失敗しました"
    end
  end

  def destroy
    if current_user.admin?
      comment = @inquiry.comments.find_by(id: params[:id])
    else
      comment = @inquiry.comments.find_by(id: params[:id], user_id: current_user.id)
    end

    if comment.inquiry.status.in?(can_comment)

      if comment&.destroy
        redirect_to inquiry_path(@inquiry), notice: "コメントを削除しました"
      else
        redirect_to inquiry_path(@inquiry), alert: "コメントを削除できませんでした"
      end
    else
      redirect_to inquiry_path(@inquiry), alert: "コメントを削除できませんでした"
    end
  end
      


  private
  
  def set_inquiry
    if current_user.admin? || current_user.manager?
      @inquiry = Inquiry.find(params[:inquiry_id])
    else
      @inquiry = current_user.inquiries.find(params[:inquiry_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def can_comment
    if current_user.admin?
      %w[draft open answered approved rejected]
    elsif current_user.manager?
      %w[draft open answered rejected]
    else
      %w[draft open answered]
    end
  end


end
