class FaqEntriesController < ApplicationController
  before_action :authenticate_user! 
  def index
    @faq_entries = FaqEntry.publicly_visible
                           .includes(:knowledge_article)
                           .search_keyword(params[:q])
                           .merge(KnowledgeArticle.by_category(params[:category_id]))
                           .page(params[:page])
                           .order(created_at: :desc)
    
    @categories = Category.order(:name)
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
