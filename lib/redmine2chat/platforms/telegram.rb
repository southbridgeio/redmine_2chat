module Redmine2chat::Platforms
  module Utils
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::CreateChat
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::GetChatLink
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::CloseChat
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::Client
  end

  class Telegram
    def initialize
      RedmineBots::Telegram.update_manager.add_handler(method(:handle_message))
    end
    
    def icon_path
      '/plugin_assets/redmine_2chat/images/telegram-icon.png'
    end

    def inactive_icon_path
      '/plugin_assets/redmine_2chat/images/telegram-inactive-icon.png'
    end

    def create_chat(title)
      bot_id = Setting.plugin_redmine_bots['telegram_bot_id']
      result = Utils.create_chat.(title, [bot_id])
      chat_id = result['id']
      result = Utils.get_chat_link.(chat_id)

      { im_id: chat_id, chat_url: result['invite_link'] }
    end

    def close_chat(im_id, message)
      send_message(im_id, message)
      Utils.close_chat.(im_id)
      Utils.get_chat_link.(im_id)
    end

    def send_message(im_id, message)
      token = Setting.plugin_redmine_bots['telegram_bot_token']
      bot   = ::Telegram::Bot::Client.new(token)

      bot.api.send_message(chat_id: im_id,
                           text: message,
                           disable_web_page_preview: true,
                           parse_mode: 'HTML')
    rescue ::Telegram::Bot::Exceptions::ResponseError => e
      if e.message.include?('429') || e.message.include?('retry later')
        sleep 5
        retry
      end
    end

    private

    def handle_message(message)
      Redmine2chat::Telegram::Bot.new(message).call if message.is_a?(::Telegram::Bot::Types::Message)
    end
  end
end
