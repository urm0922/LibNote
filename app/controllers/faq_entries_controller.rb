class FaqEntriesController < ApplicationController
  before_action :authenticate_user! 
  def index
    @faq_entries = FaqEntry.published
                           .joins(:knowledge_article)
                           .merge(KnowledgeArticle.published.where(faq_enabled: true))
                           .includes(:knowledge_article)
                           .search_keyword(params[:q])
                           .page(params[:page]).reverse_order
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
