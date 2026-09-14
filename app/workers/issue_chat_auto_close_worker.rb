class IssueChatAutoCloseWorker
  include Sidekiq::Worker

  def perform
    notify_chats_about_closed_issues
    close_old_chats
  end

  private

  def notify_chats_about_closed_issues
    chats_to_notify.find_each do |chat|
      IssueChatCloseNotificationWorker.perform_async(chat.issue_id, chat.id)
    end
  end

  def chats_to_notify
    chats_of_closed_issues
      .where('issue_chats.last_notification_at <= ?', 24.hours.ago.change(min: 59, sec: 59))
      .where(need_to_close_at: (1.day.from_now.beginning_of_day..2.days.from_now.end_of_day))
  end

  def close_old_chats
    chats_to_close.find_each do |chat|
      Redmine2chat::Operations::CloseChat.(chat.issue, chat.platform_name)
    end
  end

  def chats_to_close
    chats_of_closed_issues.where('issue_chats.need_to_close_at <= ?', Time.now)
  end

  # Chats are scoped through their issue, since auto-closing only applies to
  # issues that reached one of the configured "closing" statuses.
  def chats_of_closed_issues
    scope = IssueChat.active.joins(:issue)

    if close_issue_status_ids.present?
      scope.where(issues: { status_id: close_issue_status_ids })
    else
      scope.merge(Issue.open(false))
    end
  end

  def close_issue_status_ids
    @close_issue_status_ids ||= Array(Setting['plugin_redmine_2chat']['close_issue_statuses'])
  end
end
