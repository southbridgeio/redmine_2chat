module Redmine2chat::Telegram
  module LegacyCommands
    class IssueChatCommand < BaseBotCommand
      include Redmine2chat::Operations

      def execute
        return unless account.present?
        execute_command
      end

      def send_help
        message_text = I18n.t('redmine_2chat.bot.chat.help')
        send_message(message_text)
      end

      def issue
        issue_id = command.text.match(/^\/chat (create|info|close) (\d+)$/)[2]
        @issue ||= Issue.visible(account.user).find(issue_id)
      end

      def create_issue_chat
        if account.user.allowed_to?(:create_chat, issue.project)
          return unless plugin_module_enabled?

          creating_chat_message = I18n.t('redmine_2chat.bot.creating_chat')
          send_message(creating_chat_message)

          CreateChat.(issue)

          issue.reload
          message_text = I18n.t('redmine_2chat.journal.chat_was_created',
                                chat_url: issue.active_chat.shared_url)
          send_message(message_text)
        else
          access_denied
        end
      end

      def close_issue_chat
        if account.user.allowed_to?(:close_chat, issue.project)
          CloseChat.(issue)
          message_text = I18n.t('redmine_2chat.bot.chat.destroyed')
          send_message(message_text)
        else
          access_denied
        end
      end

      def send_chat_info
        unless account.user.allowed_to?(:view_chat_link, issue.project)
          access_denied
          return
        end

        chat = issue.active_chat
        if chat.present?
          send_message(chat.shared_url)
        else
          message_text = I18n.t('redmine_2chat.bot.chat.chat_not_found')
          send_message(message_text)
        end
      end

      def access_denied
        message_text = I18n.t('redmine_2chat.bot.access_denied')
        send_message(message_text)
      end

      def plugin_module_enabled?
        plugin_module = EnabledModule.find_by(project_id: issue.project.id, name: 'chat_telegram')
        if plugin_module.present?
          true
        else
          message_text = I18n.t('redmine_2chat.bot.module_disabled')
          send_message(message_text)
          false
        end
      end

      def execute_command
        case command.text
        when '/chat'
          send_help
        when %r{^/chat create \d+$}
          create_issue_chat
        when %r{^/chat close \d+$}
          close_issue_chat
        when %r{^/chat info \d+$}
          send_chat_info
        else
          message_text = I18n.t('redmine_2chat.bot.chat.incorrect_command') + "\n" +
                         I18n.t('redmine_2chat.bot.chat.help')
          send_message(message_text)
        end
      rescue ActiveRecord::RecordNotFound
        message_text = I18n.t('redmine_2chat.bot.chat.issue_not_found')
        send_message(message_text)
      end
    end
  end
end
