module Redmine2chat::Platforms
  module Utils
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::CreateChat
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::GetChatLink
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::CloseChat
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::Client
  end

  class Telegram
    def icon_path
      '/plugin_assets/redmine_2chat/images/telegram-icon.png'
    end

    def inactive_icon_path
      '/plugin_assets/redmine_2chat/images/telegram-inactive-icon.png'
    end

    def create_chat(title)
      bot_id = Setting.find_by_name(:plugin_redmine_bots).value['telegram_bot_id']
      result = Utils.create_chat.(title, [bot_id])
      chat_id = result['id']
      result = Utils.get_chat_link.(chat_id)

      { im_id: chat_id, chat_url: convert_link(result['invite_link']) }
    end

    def close_chat(im_id, message)
      send_message(im_id, message)
      Utils.close_chat.(im_id)
      Utils.get_chat_link.(im_id)
    end

    def send_message(im_id, message, params = {})
      message_params = {
          chat_id: im_id,
          message: message,
          bot_token: RedmineBots::Telegram.bot_token
      }.merge(params)

      RedmineBots::Telegram::Bot::MessageSender.call(message_params)
    end

    private

    def convert_link(link)
      invite_id = Addressable::URI.parse(link).request_uri.split('/').last
      "#{Setting.protocol}://#{Setting.host_name}/tg/#{invite_id}"
    end
  end
end
