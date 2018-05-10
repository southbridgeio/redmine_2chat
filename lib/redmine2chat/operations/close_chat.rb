module Redmine2chat::Operations
  class CloseChat < Base
    def initialize(issue)
      @issue = issue
    end

    def call
      @issue.init_journal(User.current, I18n.t('redmine_2chat.journal.chat_was_closed'))
      IssueChatCloseWorker.perform_async(@issue.active_chat.im_id, @issue.active_chat.platform_name, User.current.id) if @issue.save
      @issue.active_chat.update_attributes!(active: false)
    end
  end
end
