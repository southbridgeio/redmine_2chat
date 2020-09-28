module Redmine2chat::Telegram::Handlers
  class PrivateLegacyCommand
    include RedmineBots::Telegram::Bot::Handlers::HandlerBehaviour

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def description
      I18n.t("redmine_2chat.bot.private.help.#{name}")
    end

    def private?
      true
    end

    def allowed?(user)
      user.active?
    end

    def command?
      true
    end

    def call(action:, **)
      Redmine2chat::Telegram::LegacyCommands::BotCommand.new(action.message).send("execute_command_#{name}")
    end
  end
end
