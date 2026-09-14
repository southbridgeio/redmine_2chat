module Redmine2chat::Operations
  class CloseChat < Base
    MAX_ATTEMPTS = 5

    def initialize(issue, platform_name = nil)
      @issue = issue
      @platform_name = platform_name.presence&.to_s
    end

    def call
      return Failure(I18n.t('redmine_2chat.errors.no_active_chat')) if chat.nil?
      return Failure(I18n.t('redmine_2chat.errors.unknown_platform', platform: chat.platform_name)) if platform.nil?

      result = platform.close_chat(chat.im_id, closing_message)

      return give_up(result.failure) if result.failure?

      close_in_redmine(I18n.t('redmine_2chat.journal.chat_was_closed'))
      Success(true)
    end

    private

    def chat
      @chat ||= @platform_name ? @issue.active_chat_for(@platform_name) : @issue.active_chats.first
    end

    def platform
      @platform ||= Redmine2chat.platform(chat.platform_name)
    end

    def closing_message
      I18n.t("redmine_2chat.messages.closed_#{current_user.anonymous? ? 'automatically' : 'from_issue'}")
    end

    def give_up(error)
      attempts = chat.close_attempts + 1
      chat.update_columns(close_attempts: attempts)

      return Failure(error) if attempts < MAX_ATTEMPTS

      close_in_redmine(I18n.t('redmine_2chat.journal.chat_was_closed_locally',
                              platform: platform.title, count: attempts, error: error))

      Failure(I18n.t('redmine_2chat.errors.closed_locally', platform: platform.title))
    end

    def close_in_redmine(journal_text)
      Issue.transaction do
        chat.update!(active: false)
        @issue.active_chats.reset
        add_journal(@issue, journal_text)
      end
    end

    def current_user
      User.current
    end
  end
end
