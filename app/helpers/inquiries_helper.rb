module InquiriesHelper
  def inquiry_status_label(inquiry)
    {
      "draft" => "下書き",
      "open" => "未対応",
      "answered" => "回答済み",
      "approved" => "承認済み",
      "rejected" => "差し戻し"
    }.fetch(inquiry.status, inquiry.status)
  end

  def inquiry_status_class(inquiry)
    "status-#{inquiry.status}"
  end

  def can_edit_inquiry?(inquiry)
    (inquiry.user_id == current_user.id && (inquiry.draft? || inquiry.open?)) || (current_user.manager? && !inquiry.approved?) || current_user.admin?
  end
end
