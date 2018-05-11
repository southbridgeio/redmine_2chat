class IssueChatDailyReportWorker
  include Sidekiq::Worker
  include Redmine::I18n

  def perform(issue_id, yesterday_string)
    I18n.locale = Setting['default_language']

    yesterday = Date.parse yesterday_string
    time_from = yesterday.beginning_of_day
    time_to   = yesterday.end_of_day

    issue             = Issue.find(issue_id)
    chat_messages = issue.chat_messages
                             .where(sent_at: time_from..time_to)
                             .where(is_system: false)
                             .where.not(from_id: [Setting.plugin_redmine_bots['telegram_bot_id'],
                                                  Setting.plugin_redmine_bots['telegram_robot_id']])

    if chat_messages.present?
      date_string       = format_date(yesterday)
      user_names        = chat_messages.map(&:author_name).uniq
      joined_user_names = user_names.join(', ').strip

      if current_language == :ru
        users_count       = Pluralization.pluralize(user_names.count,
                                                    "#{user_names.count} человек",
                                                    "#{user_names.count} человекa",
                                                    "#{user_names.count} человек",
                                                    "#{user_names.count} человек")
        messages_count = Pluralization.pluralize(chat_messages.count,
                                                 "#{chat_messages.count} сообщение",
                                                 "#{chat_messages.count} сообщения",
                                                 "#{chat_messages.count} сообщений",
                                                 "#{chat_messages.count} сообщений")
      else
        users_count    = Pluralization.en_pluralize(user_names.count,
                                                    '1 person',
                                                    "#{user_names.count} people")
        messages_count = Pluralization.en_pluralize(chat_messages.count,
                                                    '1 message',
                                                    "#{user_names.count} messages")
      end

      users_text    = users_count
      messages_text = messages_count
      journal_text  =
        "_#{I18n.t 'redmine_2chat.journal.from_telegram'}:_ \n\n" +
        I18n.t('redmine_2chat.journal.daily_report',
               date:           date_string,
               users:          joined_user_names,
               messages_count: messages_text,
               users_count:    users_text)

      begin
        issue.init_journal(User.anonymous, journal_text)
        issue.save
      rescue ActiveRecord::StaleObjectError
        issue.reload
        retry
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
