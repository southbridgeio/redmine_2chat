class IssueChatDailyReportCronWorker
  include Sidekiq::Worker

  def perform
    if Setting.plugin_redmine_2chat['daily_report']
      yesterday = 12.hours.ago
      time_from = yesterday.beginning_of_day
      time_to   = yesterday.end_of_day

      Issue.joins(:chat_messages).where('chat_messages.sent_at >= ? and chat_messages.sent_at <= ?',
                                            time_from, time_to).uniq.find_each do |issue|
        IssueChatDailyReportWorker.perform_async(issue.id, yesterday.to_s)
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
