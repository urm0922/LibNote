class KnowledgesController < ApplicationController
  before_action :authenticate_user!

  def index
    @categories = Category.order(:name)
    @inquiries = Inquiry.approved_knowledge
                        .page(params[:page]).reverse_order

    @inquiries = @inquiries.search_keyword(params[:q])
                           .by_category(params[:category_id])
                           .page(params[:page]).reverse_order
                           #.order(created_at: :desc)
  end

  def show
    @inquiry = Inquiry.approved_knowledge.find(params[:id])
    @comments = @inquiry.comments.includes(:user).order(created_at: :asc)
  end
  
end
