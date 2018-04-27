module Redmine2chat::Operations
  class CreateChat < Base
    def initialize(issue)
      @issue = issue
    end

    def call
      Issue.transaction do
        title = "#{@issue.project.name} #{@issue.id}"
        im_id, chat_url = Redmine2chat.active_platform.create_chat(title).values_at(:im_id, :chat_url)

        attributes = {
            im_id: im_id,
            shared_url: chat_url,
            platform_name: Setting.plugin_redmine_2chat['active_platform']
        }
        if @issue.chat.present?
          @issue.chat.update!(attributes)
        else
          @issue.create_chat!(attributes)
        end

        journal_text = I18n.t('redmine_2chat.journal.chat_was_created', chat_url: chat_url)

        begin
          @issue.init_journal(User.current, journal_text)
          @issue.save!
        rescue ActiveRecord::StaleObjectError
          @issue.reload
          retry
        end
      end
    end
  end
end
