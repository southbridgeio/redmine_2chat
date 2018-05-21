module Redmine2chat::Telegram
  class Bot < RedmineBots::Telegram::Bot
    include PrivateCommand
    include GroupCommand

    attr_reader :logger, :command, :issue

    def initialize(command)
      @logger = Logger.new(Rails.root.join('log/redmine_2chat', 'bot.log'))
      @command = initialize_command(command)
    end

    private

    def initialize_command(command)
      command.is_a?(::Telegram::Bot::Types::Message) ? command : ::Telegram::Bot::Types::Message.new(command)
    end

    def execute_command
      if private_command?
        handle_private_command
      else
        handle_group_command
      end
    end

    def private_help_message
      ['Redmine Chat Telegram:', help_command_list(private_commands, namespace: 'redmine_2chat', type: 'private')].join("\n")
    end

    def group_help_message
      ['Redmine Chat Telegram:', help_command_list(group_commands, namespace: 'redmine_2chat', type: 'group') + "\n#{I18n.t('redmine_2chat.bot.group.help.hint')}"].join("\n")
    end

    def bot_token
      RedmineBots::Telegram.bot_token
    end
  end
end
