class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, except:[:index, :new, :create]
  def index
    categories = Category.search_keyword(params[:q])

    categories =
      case params[:sort]
      when "latest"
        categories.latest
      when "old"
        categories.old
      when "name_desc"
        categories.name_desc
      else
        categories.name_asc
      end

    @categories = categories.page(params[:page])

    @inquiry_counts = Inquiry.group(:category_id).count
    @knowledge_article_counts = KnowledgeArticle.group(:category_id).count                       
  end
  
  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_categories_path, notice: "カテゴリを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def new
    @category = Category.new
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "カテゴリを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @category.destroy
      redirect_to admin_categories_path, notice: "カテゴリーを削除しました"
    else
      redirect_to admin_categories_path, alert: "削除できないカテゴリーです"
    end
  end

  private
    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name)
    end

end
