class InquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry, except: [:index, :new, :create]
  before_action :set_categories, only: [:new, :create, :edit, :update]

  def mark_as_answered
    if current_user.admin? || current_user.manager?
      @inquiry.update(status: :answered)
      redirect_to inquiry_path(@inquiry), notice: "回答済みにしました"
    else
      redirect_to inquiry_path(@inquiry), alert: "権限がありません"
    end
  end

  def approve
    if current_user.admin?
      @inquiry.update(status: :approved)
      redirect_to inquiry_path(@inquiry), notice: "承認しました"
    else
      redirect_to inquiry_path(@inquiry), alert: "権限がありません"
    end
  end

  def reject
    if current_user.admin? || current_user.manager?
      @inquiry.update(status: :rejected)
      redirect_to inquiry_path(@inquiry), notice: "差し戻しました"
    else
      redirect_to inquiry_path(@inquiry), alert: "権限がありません"
    end
  end

  def index
    if current_user.admin? || current_user.manager?
      @inquiries = Inquiry.includes(:user, :category).order(created_at: :desc)
    else
      @inquiries = current_user.inquiries.includes(:user, :category).order(created_at: :desc)
    end
  end

  def new
    @inquiry = Inquiry.new
  end

  def create
    @inquiry = current_user.inquiries.new(inquiry_params)
    @inquiry.status = :open

    if @inquiry.save
      redirect_to inquiry_path(@inquiry), notice: "問い合わせを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
    if !(current_user.admin? || current_user.manager?) && !(@inquiry.draft? || @inquiry.open?) 
      redirect_to inquiries_path, alert: "確定済みの問い合わせのため編集できません"
    end
  end

  def update
    if @inquiry.draft? || @inquiry.open?
      if @inquiry.update(inquiry_params)
      redirect_to inquiry_path(@inquiry), notice: "問い合わせを更新しました"
      else
      render :edit, status: :unprocessable_entity
      end
    elsif current_user.admin? || current_user.manager?
      if @inquiry.update(inquiry_params)
        redirect_to inquiry_path(@inquiry), notice: "問い合わせを更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to inquiry_path(@inquiry), alert: "更新できません"
    end
  end

  def destroy
    if current_user.admin? || current_user.manager?
      @inquiry.destroy
      redirect_to inquiries_path, notice: "問い合わせを削除しました"
    elsif @inquiry.open? || @inquiry.draft?
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
    params.require(:inquiry).permit(:title, :body, :category_id)
  end
end
