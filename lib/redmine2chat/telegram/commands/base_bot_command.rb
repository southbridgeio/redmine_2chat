module Redmine2chat::Telegram
  module Commands
    class BaseBotCommand
      attr_reader :command, :logger

      LOGGER = Logger.new(Rails.root.join('log/chat_telegram', 'bot-command-base.log'))

      def initialize(command, logger = LOGGER)
        @command = command
        @logger = logger
      end

      def execute
        raise 'not implemented'
      end

      private

      def command_name
        command.text.match(/^\/(\w+)/)[1]
      end

      def command_arguments
        command.text.match(/^\/\w+ (.+)$/).try(:[], 1)
      end

      def arguments_help
        I18n.t("redmine_2chat.bot.arguments_help.#{command_name}")
      end

      def send_message(text, params = {})
        Redmine2chat::Platforms::Telegram.new.send_message(chat_id, text)
      end

      def account
        @account ||=
          begin
            account = TelegramAccount.find_by!(telegram_id: command.from.id)
            if account.user
              account
            else
              send_message(I18n.t('redmine_2chat.bot.account_not_connected'))
              nil
            end
          end
      rescue ActiveRecord::RecordNotFound
        send_message(I18n.t('redmine_2chat.bot.account_not_found'))
        nil
      end

      def issue_url(issue)
        Rails.application.routes.url_helpers.issue_url(
          issue,
          host: Setting.host_name,
          protocol: Setting.protocol)
      end

      def chat_id
        command.chat.id
      end

      def bot_token
        RedmineBots::Telegram.bot_token
      end
    end
  end
end
