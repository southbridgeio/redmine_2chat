module Redmine2chat::Platforms
  module Utils
    include RedmineBots::Telegram::Tdlib::DependencyProviders::CreateChat
    include RedmineBots::Telegram::Tdlib::DependencyProviders::GetChatLink
    include TelegramCommon::Tdlib::DependencyProviders::CloseChat
    include TelegramCommon::Tdlib::DependencyProviders::Client
  end

  class Telegram
    def initialize
    end

    def create_chat(issue)
      subject = "#{issue.project.name} #{issue.id}"

      bot_id = Setting.plugin_redmine_bots_common['telegram_bot_id']

      result = Utils.create_chat.(subject, [bot_id])

      chat_id = result['id']

      result = Utils.get_chat_link.(chat_id)

      im_id = chat_id
      telegram_chat_url = result['invite_link']

      if issue.chat.present?
        issue.chat.update im_id: im_id,
                                    shared_url:  telegram_chat_url
      else
        issue.create_chat im_id: im_id,
                                    shared_url:  telegram_chat_url
      end

      journal_text = I18n.t('redmine_2chat.journal.chat_was_created',
                            chat_url: telegram_chat_url)

      begin
        issue.init_journal(user, journal_text)
        issue.save
      rescue ActiveRecord::StaleObjectError
        issue.reload
        retry
      end
    end

    def close_chat(chat, message)
      TelegramMessageSenderWorker.new.perform(im_id, message)
      Utils.close_chat.(chat.im_id)
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

    def send_message(chat, message)
      token = Setting.plugin_redmine_bots['telegram_bot_token']
      bot   = Telegram::Bot::Client.new(token)

      bot.api.send_message(chat_id: chat.im_id,
                           text: message,
                           disable_web_page_preview: true,
                           parse_mode: 'HTML')
    end
  end
end
