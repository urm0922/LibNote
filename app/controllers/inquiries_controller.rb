class InquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry, only: [:mark_as_answered, :approve, :reject, :show]
  before_action :set_categories, only: [:new, :create, :edit, :update]
  before_action :branch_by_role, only: [:edit, :update, :destroy]

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
    @inquiries = Inquiry.includes(:user, :category).order(created_at: :desc)
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
  end

  def update
    if @inquiry.update(inquiry_params)
      redirect_to inquiry_path(@inquiry), notice: "問い合わせを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @inquiry.destroy
    redirect_to inquiries_path, notice: "問い合わせを削除しました"
  end

  private

  def set_inquiry
    @inquiry = Inquiry.find(params[:id])
  end

  def set_categories
    @categories = Category.order(:name)
  end

  def branch_by_role
    if current_user.admin? || current_user.manager?
      @inquiry = Inquiry.find(params[:id])
    else
      @inquiry = current_user.inquiries.find(params[:id])
    end
  end

  def inquiry_params
    params.require(:inquiry).permit(:title, :body, :category_id)
  end
end
