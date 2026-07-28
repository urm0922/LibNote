class KnowledgeArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_categories, only: [:index, :edit, :update, :drafts]
  before_action :set_visible_knowledge_article, only: :show
  before_action :require_admin!, only: [:edit, :update, :destroy, :drafts, :publish, :draft]
  before_action :set_knowledge_article, only: [:edit, :update, :destroy, :publish, :draft]

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
    @knowledge_article.faq_entries.build if @knowledge_article.faq_entries.empty?
  end

  def update
    @knowledge_article.assign_attributes(knowledge_article_params)

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

  def drafts
    @knowledge_articles = KnowledgeArticle.draft
                                          .includes(:category, :author)
                                          .page(params[:page]).reverse_order
  end

  def publish
    if @knowledge_article.draft?

      ActiveRecord::Base.transaction do
        @knowledge_article.update!(
          status: :published,
          published_at: Time.current
        )
    
        if @knowledge_article.faq_enabled?
          @knowledge_article.faq_entries.each do |faq_entry|
            faq_entry.update!(
              status: :published,
              published_at: Time.current
            )
          end
        end
      end
      redirect_to knowledge_article_path(@knowledge_article), notice: "ナレッジを公開しました"
    elsif @knowledge_article.archived?
      redirect_to knowledge_article_path(@knowledge_article), alert: "このナレッジは公開できない状態です"
    else
      redirect_to knowledge_article_path(@knowledge_article), alert: "既に公開済みのナレッジです"
    end
  end
  
  def draft
    if @knowledge_article.published?

      ActiveRecord::Base.transaction do
        @knowledge_article.update!(
          status: :draft
        )
    
        if @knowledge_article.faq_enabled?
          @knowledge_article.faq_entries.each do |faq_entry|
            faq_entry.update!(
              status: :draft
            )
          end
        end
      end

      redirect_to knowledge_article_path(@knowledge_article), notice: "ナレッジを下書きに戻しました"
    elsif @knowledge_article.archived?
      redirect_to knowledge_article_path(@knowledge_article), alert: "このナレッジは下書きに戻せない状態です"
    else
      redirect_to knowledge_article_path(@knowledge_article), alert: "既に下書きのナレッジです"
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
    params.require(:knowledge_article).permit(
      :title,
      :body,
      :category_id,
      :faq_enabled,
      faq_entries_attributes: [
        :id,
        :question,
        :answer
      ]
    )
  end
end
