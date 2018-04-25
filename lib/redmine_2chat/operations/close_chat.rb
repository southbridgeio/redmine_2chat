module Redmine2chat::Operations
  class CloseChat < Base
    def initialize(issue)
      @issue = issue
    end

    def call
      @issue.init_journal(User.current, I18n.t('redmine_2chat.journal.chat_was_closed'))
      IssueChatCloseWorker.perform_async(@issue.chat.im_id, @issue.chat.platform_name, User.current.id) if @issue.save
      @issue.chat.destroy
    end
  end
end