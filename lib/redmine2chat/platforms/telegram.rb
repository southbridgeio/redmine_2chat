module Redmine2chat::Platforms
  class Telegram
    include Dry::Monads::Result::Mixin

    class ChatUpgradedError
      def self.===(e)
        e.is_a?(::Telegram::Bot::Exceptions::ResponseError) && e.message.include?('group chat was upgraded to a supergroup chat')
      end
    end

    def icon_path
      '/plugin_assets/redmine_2chat/images/telegram-icon.png'
    end

    def inactive_icon_path
      '/plugin_assets/redmine_2chat/images/telegram-inactive-icon.png'
    end

    def create_chat(title)
      current_user = User.current
      user_telegram_account = current_user.telegram_account
      bot_id = Setting.find_by_name(:plugin_redmine_bots).value['telegram_bot_id'].presence

      RedmineBots::Telegram::Tdlib.wrap do
        promise = RedmineBots::Telegram::Tdlib::CreateChat.(title, [bot_id].compact).then do |chat|
          RedmineBots::Telegram::Tdlib::ToggleChatAdmin.(chat.id, bot_id)

          if user_telegram_account&.username
            RedmineBots::Telegram::Tdlib::AddToChat.(chat.id, user_telegram_account.username).then do
              RedmineBots::Telegram.bot.async.promote_chat_member(chat_id: chat.id,
                                                                  user_id: user_telegram_account.telegram_id.to_i,
                                                                  can_manage_chat: true,
                                                                  can_change_info: true,
                                                                  can_post_messages: true,
                                                                  can_edit_messages: true,
                                                                  can_delete_messages: true,
                                                                  can_invite_users: true,
                                                                  can_restrict_members: true,
                                                                  can_pin_messages: true,
                                                                  can_manage_topics: true,
                                                                  can_promote_members: true,
                                                                  can_manage_video_chats: true,
                                                                  can_post_stories: false,
                                                                  can_edit_stories: false,
                                                                  can_delete_stories: false,
                                                                  is_anonymous: false
              )
            end
          end


          invite_link = RedmineBots::Telegram::Tdlib::GetChatLink.(chat.id).value!.invite_link
          { im_id: chat.id, chat_url: convert_link(invite_link) }
        end

        RedmineBots::Telegram::Tdlib.permit_concurrent_loads { Success(promise.value!) }
      end
    rescue TD::Error => error
      Failure("Tdlib error: #{error.message}")
    end

    def close_chat(im_id, message)
      send_message(im_id, message)
      RedmineBots::Telegram::Tdlib.wrap do
        promise = RedmineBots::Telegram::Tdlib::CloseChat.(im_id)
        RedmineBots::Telegram::Tdlib.permit_concurrent_loads { Success(promise.value!) }
      end
    rescue TD::Error => error
      Failure("Tdlib error: #{error.message}")
    end

    def send_message(im_id, message, params = {})
      message_params = {
          chat_id: im_id,
          text: message,
          parse_mode: 'HTML'
      }.merge(params)

      begin
        RedmineBots::Telegram.bot.send_message(**message_params)
      rescue ChatUpgradedError => e
        new_chat_id = e.send(:data).dig('parameters', 'migrate_to_chat_id')
        issue_chat = IssueChat.find_by(im_id: im_id, platform_name: 'telegram')
        new_chat_id && issue_chat&.update!(im_id: new_chat_id) || raise(e)
        message_params.merge!(chat_id: new_chat_id) && retry
      end
    end

    private

    def convert_link(link)
      invite_id = Addressable::URI.parse(link).request_uri.split('/').last
      # Trim leading plus sign for compatibility with Telegram API 5.4
      invite_id = invite_id[1..-1] if invite_id[0] == "+"
      "#{Setting.protocol}://#{Setting.host_name}/tg/#{invite_id}"
    end
  end
end
