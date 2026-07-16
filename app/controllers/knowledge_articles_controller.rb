class KnowledgeArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_categories, only: [:index, :edit, :update]
  before_action :set_visible_knowledge_article, only: :show
  before_action :require_admin!, only: [:edit, :update, :destroy]
  before_action :set_knowledge_article, only: [:edit, :update, :destroy]

  def index
    @knowledge_articles = KnowledgeArticle.published
                                          .includes(:category, :author, :inquiry)
                                          .search_keyword(params[:q])
                                          .by_category(params[:category_id])
                                          .page(params[:page]).reverse_order
  end

  def show
    @comments = @knowledge_article.inquiry.comments.includes(:user).order(created_at: :asc)
  end

  def edit
  end

  def update
    @knowledge_article.assign_attributes(knowledge_article_params)
    @knowledge_article.published_at ||= Time.current if @knowledge_article.published?

    if @knowledge_article.save
      redirect_to knowledge_article_path(@knowledge_article), notice: "ナレッジを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @knowledge_article.destroy
      redirect_to knowledge_articles_path, notice: "ナレッジを削除しました"
    else
      redirect_to knowledge_article_path(@knowledge_article), alert: "ナレッジの削除に失敗しました"
    end
  end

  private

  def set_visible_knowledge_article
    @knowledge_article =
      if current_user.admin?
        KnowledgeArticle.find(params[:id])
      else
        KnowledgeArticle.published.find(params[:id])
      end
  end

  def set_knowledge_article
    @knowledge_article = KnowledgeArticle.find(params[:id])
  end

  def set_categories
    @categories = Category.order(:name)
  end

  def require_admin!
    return if current_user.admin?

    redirect_to knowledge_articles_path, alert: "ナレッジは管理者のみ変更できます"
  end

  def knowledge_article_params
    params.require(:knowledge_article).permit(:title, :body, :category_id, :status, :published_at)
  end
end
