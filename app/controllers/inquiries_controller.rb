class InquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry, except: [:index, :new, :create, :confirm]
  before_action :set_categories, only: [:index, :new, :create, :edit, :update]

  def mark_as_answered
    if @inquiry.approved? && !current_user.admin?
      redirect_to inquiry_path(@inquiry), alert: "承認済の問い合わせは編集できません"
      return
    end

    if current_user.admin? || current_user.manager?
      @inquiry.update(status: :answered)
      redirect_to inquiry_path(@inquiry), notice: "回答済みにしました"
    else
      redirect_to inquiry_path(@inquiry), alert: "権限がありません"
    end
  end

  def approve
    if current_user.admin?
      @inquiry.publish_as_knowledge!
      redirect_to inquiry_path(@inquiry), notice: "承認しました"
    else
      redirect_to inquiry_path(@inquiry), notice: "権限がありません"
    end  
  end

  def reject
    if @inquiry.approved? && !current_user.admin?
      redirect_to inquiry_path(@inquiry), alert: "承認済の問い合わせは編集できません"
      return
    end

    if current_user.admin? || current_user.manager?
      @inquiry.update(status: :rejected)
      redirect_to inquiry_path(@inquiry), notice: "差し戻しました"
    else
      redirect_to inquiry_path(@inquiry), alert: "権限がありません"
    end
  end

  def index
    if current_user.admin? || current_user.manager?
      @inquiries = Inquiry.where.not(status: :draft)
                          .or(Inquiry.where(status: :draft, user: current_user))
                          .includes(:user, :category)
                          .page(params[:page]).reverse_order
      @inquiries = @inquiries.search_keyword(params[:q])
                             .by_category(params[:category_id])
                             .by_status(params[:status])
                             .page(params[:page]).reverse_order
    else
      @inquiries = current_user.inquiries.includes(:user, :category).page(params[:page]).reverse_order#order(created_at: :desc)
      @inquiries = @inquiries.search_keyword(params[:q])
                             .by_category(params[:category_id])
                             .by_status(params[:status])
                             .page(params[:page]).reverse_order
    end

  end

  def new
    @inquiry = Inquiry.new
  end

  def create
    unless params.dig(:inquiry, :status).in?(%w[draft open])
      @inquiry = current_user.inquiries.new(inquiry_params.except(:status))
      render :new, status: :unprocessable_entity
      return
    end
      
    @inquiry = current_user.inquiries.new(inquiry_params)

    if @inquiry.save
      redirect_to inquiry_path(@inquiry), notice: "問い合わせを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    @inquiries = current_user.inquiries.draft.page(params[:page]).reverse_order

  end

  def show
    @comment = Comment.new
    @comments = @inquiry.comments.includes(:user).order(created_at: :asc)
  end

  def edit
    if @inquiry.approved? && !current_user.admin?
      redirect_to inquiry_path(@inquiry), alert: "承認済の問い合わせは編集できません"
      return
    end

    if !(current_user.admin? || current_user.manager?) && !(@inquiry.draft? || @inquiry.open?) 
      redirect_to inquiry_path(@inquiry), alert: "確定済みの問い合わせのため編集できません"
    end
  end

  def update
    can_update = current_user.admin? || @inquiry.draft? || @inquiry.open? || (current_user.manager? && !@inquiry.approved?)
    unless can_update
      redirect_to inquiry_path(@inquiry), alert: "更新できません"
      return
    end

    requested_status = params.dig(:inquiry, :status)
    allowed_statuses =
      if current_user.admin?
        %w[draft open answered approved rejected]
      elsif current_user.manager?
        %w[draft open answered rejected]
      else
        %w[draft open]
      end
      
    if requested_status && !requested_status.in?(allowed_statuses)
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
    can_destroy = if current_user.admin?
                    %w[draft open answered approved rejected]
                  elsif current_user.manager?
                    %w[draft open answered rejected]
                  else
                    %w[draft open]
                  end
    if @inquiry.status.in?(can_destroy)
      @inquiry.destroy
      redirect_to inquiries_path, notice: "問い合わせを削除しました"
    else
      redirect_to inquiry_path(@inquiry), alert: "確定済みのため削除できません"
    end
  end

  private

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
    params.require(:inquiry).permit(:title, :body, :category_id, :status)
  end
end
