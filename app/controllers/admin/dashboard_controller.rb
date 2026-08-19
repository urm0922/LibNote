class Admin::DashboardController < Admin::BaseController
  
  def index
    @no_answers_count = Inquiry.open.count
    
    pending_approvals = Inquiry.answered
    @pending_approvals_count = pending_approvals.count
    @pending_approvals = pending_approvals.includes(:category, :user)
                                          .with_attached_images
                                          .order(created_at: :desc)
                                          .limit(3)
    
    pending_published_articles = KnowledgeArticle.draft
    @pending_published_articles_count = pending_published_articles.count
    @pending_published_articles = pending_published_articles.includes(
                                                                :category,
                                                                :author,
                                                                inquiry: { images_attachments: :blob }
                                                                )
                                                            .order(created_at: :desc)
                                                            .limit(3)


  end
end
