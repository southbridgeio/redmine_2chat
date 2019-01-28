class IssueChatAutoCloseWorker
  include Sidekiq::Worker

  def perform
    notify_chats_about_closed_issues
    close_old_chats
  end

  private

  def notify_chats_about_closed_issues
    need_to_notify_issues.find_each do |issue|
      IssueChatCloseNotificationWorker.perform_async(issue.id)
    end
  end

  def need_to_notify_issues
    issues = Issue.joins(:chats)
                  .where('issue_chats.last_notification_at <= ?', 24.hours.ago.change(min: 59, sec: 59))

    if close_issue_status_ids.present?
      issues = issues.where(status_id: close_issue_status_ids)
    else
      issues = issues.open(false)
    end

    issues
  end

  def close_old_chats
    need_to_close_issues.find_each do |issue|
      im_id = issue.active_chat.im_id

      issue.active_chat.update_column(:active, false)
      issue.active_chat.platform.close_chat(im_id, '')
    end
  end

  def need_to_close_issues
    if close_issue_status_ids.present?
      Issue.joins(:active_chat)
        .where(status_id: close_issue_status_ids)
        .where('issue_chats.need_to_close_at <= ?', Time.now)
    else
      Issue.open(false).joins(:active_chat)
        .where('issue_chats.need_to_close_at <= ?', Time.now)
    end
  end

  def close_issue_status_ids
    @close_issue_status_ids ||= Setting['plugin_redmine_2chat']['close_issue_statuses']
  end
end
