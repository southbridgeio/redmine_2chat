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

    def kick_locked_users
      Utils.client.on_ready do |client|
        begin
          IssueChat.all.each do |group|
            chat = client.broadcast_and_receive('@type' => 'getChat', 'chat_id' => group.im_id)

            group_info = client.broadcast_and_receive('@type' => 'getBasicGroupFullInfo',
                                                      'basic_group_id' => chat.dig('type', 'basic_group_id')
            )
            #(@logger.warn("Error while fetching group ##{group.im_id}: #{group_info.inspect}") && next) if group_info['@type'] == 'error'

            telegram_user_ids = group_info['members'].map {|m| m['user_id']}

            telegram_accounts.preload(:user).where(im_id: telegram_user_ids).each do |account|
              user = account.user
              next unless user&.locked?
              result = client.broadcast_and_receive('@type' => 'setChatMemberStatus',
                                                    'chat_id' => group.im_id,
                                                    'user_id' => account.im_id,
                                                    'status' => {'@type' => 'chatMemberStatusLeft'})
              #@logger.info("Kicked user ##{user.id} from chat ##{group.im_id}") if result['@type'] == 'ok'
              #@logger.error("Failed to kick user ##{user.id} from chat ##{group.im_id}: #{result.inspect}") if result['@type'] == 'error'
            end
          end
        rescue Timeout::Error
          tries ||= 3
          sleep 2
          retry unless (tries -= 1).zero?
        ensure
          client.close
        end
      end
    end

    def send_message(im_id, message)
      token = Setting.plugin_redmine_bots['telegram_bot_token']
      bot   = ::Telegram::Bot::Client.new(token)

      bot.api.send_message(chat_id: im_id,
                           text: message,
                           disable_web_page_preview: true,
                           parse_mode: 'HTML')
    end

    private

    def handle_message(message)
      Redmine2chat::Telegram::Bot.new(message).call if message.is_a?(::Telegram::Bot::Types::Message)

      group = IssueChat.find_by(im_id: message.chat.id, platform_name: 'telegram')

      return if group.blank?

      chat_message = ChatMessage.find_or_initialize_by(im_id: message.message_id, issue_chat_id: group.id)

      sent_at = Time.at message.date
      from = message.from
      from_id = from.id
      from_first_name = from.first_name
      from_last_name = from.last_name
      from_username = from.username
      message_text =
          if message.text
            message.text
          elsif message.new_chat_members
            'joined'
          elsif message.left_chat_member
            'left_chat'
          elsif message.group_chat_created
            'chat_was_created'
          else
            'Unknown action'
          end

      chat_message.sent_at = sent_at
      chat_message.im_id = from_id
      chat_message.first_name = from_first_name
      chat_message.last_name = from_last_name
      chat_message.username = from_username
      chat_message.message = message_text

      chat_message.save!
    end
  end
end
