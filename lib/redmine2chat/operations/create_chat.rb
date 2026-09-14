module Redmine2chat::Operations
  class CreateChat < Base
    def initialize(issue, platform_name = nil)
      @issue = issue
      @platform_name = (platform_name.presence || Redmine2chat.active_platform_names.first).to_s
    end

    def call
      platform = Redmine2chat.platform(@platform_name)

      return Failure(I18n.t('redmine_2chat.errors.unknown_platform', platform: @platform_name)) if platform.nil?
      return Failure(I18n.t('redmine_2chat.errors.platform_disabled', platform: platform.title)) unless Redmine2chat.active_platform?(@platform_name)

      title = "#{@issue.project.name} #{@issue.id}"

      platform.create_chat(title, @issue).fmap do |result|
        Issue.transaction do
          im_id, chat_url = result.values_at(:im_id, :chat_url)
          attributes = { im_id: im_id, shared_url: chat_url, platform_name: @platform_name }

          existing_chat = @issue.active_chat_for(@platform_name)

          if existing_chat.present?
            existing_chat.update!(attributes)
          else
            @issue.chats.create!(attributes)
          end

          @issue.active_chats.reset

          add_journal(@issue, I18n.t('redmine_2chat.journal.chat_was_created', chat_url: chat_url))
        end
      end
    end
  end
end
