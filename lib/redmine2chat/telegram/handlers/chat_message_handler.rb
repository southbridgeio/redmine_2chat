module Redmine2chat::Telegram::Handlers
  class ChatMessageHandler
    include RedmineBots::Telegram::Bot::Handlers::HandlerBehaviour

    def match?(action)
      action.group? && action.message? && !action.command? && IssueChat.active.exists?(platform_name: 'telegram', im_id: action.chat_id)
    end

    def call(action:, **)
      Redmine2chat::Telegram::Bot.new(action.message).execute_command
    end
  end
end
