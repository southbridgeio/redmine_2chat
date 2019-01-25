module Redmine2chat::Platforms
  class Telegram
    def icon_path
      '/plugin_assets/redmine_2chat/images/telegram-icon.png'
    end

    def inactive_icon_path
      '/plugin_assets/redmine_2chat/images/telegram-inactive-icon.png'
    end

    def create_chat(title)
      bot_id = Setting.find_by_name(:plugin_redmine_bots).value['telegram_bot_id'].presence

      RedmineBots::Telegram::Tdlib::CreateChat.(title, [bot_id].compact).then do |chat|
        invite_link = RedmineBots::Telegram::Tdlib::GetChatLink.(chat.id).value!.invite_link
        { im_id: chat.id, chat_url: convert_link(invite_link) }
      end
    end

    def close_chat(im_id, message)
      send_message(im_id, message)
      RedmineBots::Telegram::Tdlib::CloseChat.(im_id)
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
