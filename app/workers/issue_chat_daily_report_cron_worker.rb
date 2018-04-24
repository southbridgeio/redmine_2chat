class IssueChatDailyReportCronWorker
  include Sidekiq::Worker

  TELEGRAM_GROUP_DAILY_REPORT_CRON_LOG = Logger.new(Rails.root.join('log/chat_telegram',
                                                                    'telegram-group-daily-report-cron.log'))

  def perform
    if Setting.plugin_redmine_chat_telegram['daily_report']
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
