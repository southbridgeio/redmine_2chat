module Redmine2chat::Operations
  class CloseChat < Base
    def initialize(issue)
      @issue = issue
    end

    def call
      message = I18n.t("redmine_2chat.messages.closed_#{current_user.anonymous? ? 'automatically' : 'from_issue'}")

      platform.close_chat(@issue.active_chat.im_id, message).fmap do
        Issue.transaction do
          @issue.init_journal(current_user, I18n.t('redmine_2chat.journal.chat_was_closed'))
          @issue.active_chat.update!(active: false)
          @issue.save!
        end
      end
    end

    private

    def chat
      @issue.active_chat
    end

    def platform
      Redmine2chat.platforms[chat.platform_name]
    end

    def current_user
      User.current
    end
  end
end
