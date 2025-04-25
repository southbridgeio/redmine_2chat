module Redmine2chat::Operations
  class CreateChat < Base
    def initialize(issue)
      @issue = issue
    end

    def call
      title = "#{@issue.project.name} #{@issue.id}"
      Redmine2chat.active_platform.create_chat(title, @issue).fmap do |result|
        Issue.transaction do
          im_id, chat_url = result.values_at(:im_id, :chat_url)
          attributes = {
              im_id: im_id,
              shared_url: chat_url,
              platform_name: Setting.plugin_redmine_2chat['active_platform']
          }
          if @issue.active_chat.present?
            @issue.active_chat.update!(attributes)
          else
            @issue.chats.create!(attributes)
          end

          journal_text = I18n.t('redmine_2chat.journal.chat_was_created', chat_url: chat_url)

          @issue.init_journal(User.current, journal_text)
          @issue.save!
        end
      end
    end
  end
end
