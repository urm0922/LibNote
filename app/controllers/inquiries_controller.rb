class InquiriesController < ApplicationController
  rescue_from Pundit::NotAuthorizedError,
              with: :handle_unauthorized_inquiry
  before_action :authenticate_user!
  before_action :set_inquiry, except: [:index, :new, :create, :confirm]
  before_action :set_categories, only: [:index, :new, :create, :edit, :update]

  def mark_as_answered
    authorize @inquiry, :mark_as_answered?
    
    @inquiry.update(status: :answered)
    redirect_to inquiry_path(@inquiry), notice: "回答済みにしました"
  end

  def approve
    authorize @inquiry, :approve?
      Inquiries::ApproveAndGenerateDrafts.new(
        inquiry: @inquiry,
        approver: current_user
      ).call

    redirect_to inquiry_path(@inquiry), notice: "承認しました"
    
    rescue Inquiries::ApproveAndGenerateDrafts::GenerationError
      redirect_to inquiry_path(@inquiry), alert: "AIによる下書き生成に失敗しました。時間をおいて再度お試しください"
    
    rescue Inquiries::ApproveAndGenerateDrafts::AlreadyApprovedError
      redirect_to inquiry_path(@inquiry), alert: "この問い合わせはすでに承認されています"
      
  end

  def reject
    authorize @inquiry, :reject?
    
    @inquiry.update(status: :rejected)
    redirect_to inquiry_path(@inquiry), notice: "差し戻しました"
  end

  def index
    if current_user.admin? || current_user.manager?
      @inquiries = Inquiry.where.not(status: :draft)
                          .or(Inquiry.where(status: :draft, user: current_user))
                          .includes(:user, :category)
                          .page(params[:page]).order(created_at: :desc)
      @inquiries = @inquiries.search_keyword(params[:q])
                             .by_category(params[:category_id])
                             .by_status(params[:status])
                             .page(params[:page]).order(created_at: :desc)
    else
      @inquiries = current_user.inquiries.includes(:user, :category).page(params[:page]).order(created_at: :desc)
      @inquiries = @inquiries.search_keyword(params[:q])
                             .by_category(params[:category_id])
                             .by_status(params[:status])
                             .page(params[:page]).order(created_at: :desc)
    end

  end

  def new
    @inquiry = Inquiry.new
  end

  def create
    allowed_statuses = policy(Inquiry).creatable_statuses
    requested_status = params.dig(:inquiry, :status)

    unless requested_status.in?(allowed_statuses)
      @inquiry = current_user.inquiries.new(inquiry_params.except(:status))
      render :new, status: :unprocessable_entity
      return
    end
    
    @inquiry = current_user.inquiries.new(inquiry_params)

    authorize @inquiry

    if @inquiry.save
      redirect_to inquiry_path(@inquiry), notice: "問い合わせを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    @inquiries = current_user.inquiries.draft.page(params[:page]).order(created_at: :desc)

  end

  def show
    authorize @inquiry
    @comment = @inquiry.comments.build(user: current_user)
    @comments = @inquiry.comments.includes(:user).order(created_at: :asc)
  end

  def edit
    authorize @inquiry
  end

  def update
    authorize @inquiry

    requested_status = params.dig(:inquiry, :status)
    allowed_statuses = policy(@inquiry).permitted_statuses
      
    if requested_status.present? && !requested_status.in?(allowed_statuses)
      @inquiry.assign_attributes(inquiry_params.except(:status))
      @inquiry.errors.add(:status, "が不正です")
      render :edit, status: :unprocessable_entity
      return
    end

    if @inquiry.update(inquiry_params)
      redirect_to inquiry_path(@inquiry), notice: "問い合わせを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @inquiry
    if @inquiry.destroy
      redirect_to inquiries_path, notice: "問い合わせを削除しました"
    else
      redirect_to inquiry_path(@inquiry), alert: "関連するナレッジ記事が存在するため削除できません"
    end
  end

  private

  def handle_unauthorized_inquiry(exception)
    if exception.query == "show?"
      redirect_to inquiries_path, alert: "この問い合わせを閲覧する権限がありません"
      return
    end
    
    message =
      case exception.query
      when "edit?"
        if exception.record.approved?
          "承認済の問い合わせは編集できません"
        else
          "確定済みの問い合わせのため編集できません"
        end
      when "update?"
        "更新できません"
      when "destroy?"
        "確定済みのため削除できません"
      when "mark_as_answered?", "reject?"
        "この問い合わせを処理する権限がありません"
      else
        "権限がありません"
      end

    redirect_to inquiry_path(exception.record), alert: message
  end

  def set_inquiry
    if current_user.admin? || current_user.manager?
      @inquiry = Inquiry.find(params[:id])
    else
      @inquiry = current_user.inquiries.find(params[:id])
    end
  end

  def set_categories
    @categories = Category.order(:name)
  end

  def inquiry_params
    params.require(:inquiry).permit(:title, :body, :category_id, :status, images: [])
  end
end
