class IssueChatCloseNotificationWorker
  include Sidekiq::Worker
  include ActionView::Helpers::DateHelper
  include ApplicationHelper

  def perform(issue_id)
    I18n.locale = Setting['default_language']

    @issue = Issue.find_by id: issue_id

    return unless issue.present?
    return unless issue_chat.present?

    if issue_chat.im_id.present?
      send_chat_notification
      issue_chat.update last_notification_at: Time.now
    else
      issue_chat.destroy
    end
  end

  private

  attr_reader :issue

  def send_chat_notification
    im_id = issue_chat.im_id

    logger.debug "chat##{im_id}"

    close_message_text = I18n.t('redmine_2chat.messages.close_notification',
                                time_in_words: time_in_words)

    IssueChatMessageSenderWorker.perform_async(im_id, issue_chat.platform_name, close_message_text)
  end

  def time_in_words
    (days_count > 0)? days_string : hours_string
  end

  def hours_string
    l_key = 'datetime.distance_in_words.x_hours'

    if current_language == :ru
      Pluralization.pluralize(hours_count,
                              l("#{l_key}.one",  count: hours_count),
                              l("#{l_key}.few",  count: hours_count),
                              l("#{l_key}.many", count: hours_count),
                              l("#{l_key}.other",count: hours_count))
    else
      Pluralization.en_pluralize(hours_count,
                                 l("#{l_key}.one"),
                                 l("#{l_key}.other", count: hours_count))
    end
  end

  def days_string
    l_key = 'datetime.distance_in_words.x_days'

    if current_language == :ru
      Pluralization.pluralize(days_count,
                              l("#{l_key}.one",  count: days_count),
                              l("#{l_key}.few",  count: days_count),
                              l("#{l_key}.many", count: days_count),
                              l("#{l_key}.other",count: days_count))
    else
      Pluralization.en_pluralize(days_count,
                              l("#{l_key}.one"),
                              l("#{l_key}.other", count: days_count))
    end
  end

  def hours_count
    time_diff = (Time.current - issue_chat.need_to_close_at)
    (time_diff / 1.hour).round.abs
  end

  def days_count
    issue_chat.need_to_close_at.to_date.mjd - Date.today.mjd
  end

  def issue_chat
    @issue_chat ||= issue.active_chat
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram',
                                           'telegram-group-close-notification.log'))
  end
end
