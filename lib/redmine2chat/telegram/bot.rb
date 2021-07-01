module Redmine2chat::Telegram
  class Bot
    include PrivateCommand
    include GroupCommand

    attr_reader :logger, :command, :issue

    def initialize(command)
      @logger = Logger.new(Rails.root.join('log/redmine_2chat', 'bot.log'))
      @command = initialize_command(command)
    end

    def execute_command
      if private_command?
        handle_private_command
      else
        handle_group_command
      end
    end

    private

    def private_command?
      command.chat.type == 'private'
    end

    def initialize_command(command)
      command.is_a?(::Telegram::Bot::Types::Message) ? command : ::Telegram::Bot::Types::Message.new(command)
    end

    def command_name
      @command_name ||= command_text.scan(%r{^/(\w+)}).flatten.first
    end

    def command_text
      @command_text ||= command.text.to_s
    end

    def chat_id
      command.chat.id
    end

    def send_message(message, params: {})
      Redmine2chat.platforms['telegram'].send_message(chat_id, message, params)
    end
  end
end
