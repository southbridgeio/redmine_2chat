module Redmine2chat::Telegram::Handlers
  class GroupLegacyCommand
    include RedmineBots::Telegram::Bot::Handlers::HandlerBehaviour

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def description
      I18n.t("redmine_2chat.bot.group.help.#{name}")
    end

    def private?
      false
    end

    def group?
      true
    end

    def allowed?(user)
      user.active?
    end

    def command?
      true
    end

    def call(action:, **)
      Redmine2chat::Telegram::Bot.new(action.message).execute_command
    end
  end
end
