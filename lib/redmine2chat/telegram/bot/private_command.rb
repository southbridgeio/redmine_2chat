module Redmine2chat::Telegram
  class Bot
    module PrivateCommand
      private

      def private_common_commands
        ['help']
      end

      def private_plugin_commands
        %w[new hot me deadline dl spent yspent last chat task issue help ih th]
      end

      def private_ext_commands
        []
      end

      def private_commands
        (private_common_commands +
          private_plugin_commands +
          private_ext_commands
        ).uniq
      end

      def handle_private_command
        executing_command = TelegramExecutingCommand
                            .joins(:account)
                            .find_by(telegram_accounts: { telegram_id: command.from.id })
        if private_commands.include?(command_name) || executing_command.present?
          if private_common_command?
            execute_private_command
          else
            Redmine2chat::Telegram::LegacyCommands::BotCommand.new(command, logger).execute
          end
        elsif group_commands.include?(command_name)
          send_message(I18n.t('telegram_common.bot.private.group_command'))
        end
      end

      def private_common_command?
        private_common_commands.include?(command_name)
      end
    end
  end
end
