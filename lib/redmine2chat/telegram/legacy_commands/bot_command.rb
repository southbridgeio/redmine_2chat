module Redmine2chat::Telegram
  module LegacyCommands
    class BotCommand < BaseBotCommand
      @@command_helps = []
      cattr_accessor :command_helps, instance_accessor: false

      def execute
        if executing_command.present? && command.text =~ /\/cancel/
          executing_command.cancel(command)
        elsif executing_command.present?
          executing_command.continue(command)
        else
          execute_command
        end
      end

      def execute_command_new
        Redmine2chat::Telegram::LegacyCommands::NewIssueCommand.new(command).execute
      end

      def execute_find_issues_command
        Redmine2chat::Telegram::LegacyCommands::FindIssuesCommand.new(command, find_issues_logger).execute
      end

      alias execute_command_hot execute_find_issues_command
      alias execute_command_me execute_find_issues_command
      alias execute_command_dl execute_find_issues_command
      alias execute_command_deadline execute_find_issues_command

      def find_issues_logger
        Redmine2chat::Telegram::LegacyCommands::FindIssuesCommand::LOGGER
      end

      def execute_command_spent
        Redmine2chat::Telegram::LegacyCommands::TimeStatsCommand.new(command).execute
      end

      def execute_command_yspent
        Redmine2chat::Telegram::LegacyCommands::TimeStatsCommand.new(command).execute
      end

      def execute_command_last
        Redmine2chat::Telegram::LegacyCommands::LastIssuesNotesCommand.new(command).execute
      end

      def execute_command_connect
        Redmine2chat::Telegram::LegacyCommands::ConnectCommand.new(command, logger).execute
      end

      def execute_command_chat
        Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
      end

      def execute_command_issue
        Redmine2chat::Telegram::LegacyCommands::EditIssueCommand.new(command).execute
      end

      def execute_command_become_chat_admin
        Redmine2chat::Telegram::LegacyCommands::BecomeChatAdmin.new(command).execute
      end

      alias execute_command_task execute_command_issue

      def execute_command_ih
        command.text = '/issue hot'
        execute_command_issue
      end

      alias execute_command_th execute_command_ih

      private

      def executing_command
        @executing_command ||= TelegramExecutingCommand
                             .joins(:account)
                             .find_by(telegram_accounts: { telegram_id: command.from.id })
      end

      def execute_command
        send("execute_command_#{command_name}")
      end
    end
  end
end
