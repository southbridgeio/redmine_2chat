module Redmine2chat::Platforms
  module Utils
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::CreateChat
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::GetChatLink
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::CloseChat
    extend RedmineBots::Telegram::Tdlib::DependencyProviders::Client
  end

  class Telegram
    def initialize
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

            TelegramCommon::Account.preload(:user).where(im_id: telegram_user_ids).each do |account|
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
  end
end
