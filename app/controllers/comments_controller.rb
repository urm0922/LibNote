class CommentsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError,
              with: :handle_unauthorized_comment
  before_action :authenticate_user!
  before_action :set_inquiry

  def create
    comment = @inquiry.comments.new(comment_params)
    comment.user_id = current_user.id
    authorize comment    
    
      if comment.save
        redirect_to inquiry_path(@inquiry), notice: "コメントを作成しました"
      else
        redirect_to inquiry_path(@inquiry), alert: "コメント作成に失敗しました"
      end
  end

  def destroy
    comment = @inquiry.comments.find_by(id: params[:id])
    
    unless comment
      redirect_to inquiry_path(@inquiry),
                  alert: "コメントを削除できませんでした"
      return
    end    

    authorize comment

    if comment.destroy
      redirect_to inquiry_path(@inquiry), notice: "コメントを削除しました"
    else
      redirect_to inquiry_path(@inquiry), alert: "コメントを削除できませんでした"
    end
  end
      


  private
  
  def handle_unauthorized_comment(exception)
    message =
      case exception.query
      when "create?"
        "コメント作成に失敗しました"
      when "destroy?"
        "コメントを削除できませんでした"
      end

    redirect_to inquiry_path(exception.record.inquiry), alert: message
  end

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
end
