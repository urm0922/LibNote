module Admin::CategoriesHelper
  def category_unused?(category)
    @inquiry_counts[category.id].to_i.zero? && @knowledge_article_counts[category.id].to_i.zero?
  end

  def category_label(category)
    if category_unused?(category)
      "未使用"
    else
      "使用中"
    end
  end

  def category_status(category)
    if category_unused?(category)
      "unused"
    else
      "used"
    end
  end

  def category_status_class(category)
    "status-#{category_status(category)}"
  end
end
