class IssueChatKickLockedUsersWorker
  include Sidekiq::Worker
  include RedmineBots::Telegram::Tdlib::DependencyProviders::Client

  def initialize(logger = Logger.new(Rails.env.production? ? Rails.root.join('log/redmine_2chat','telegram-kick-locked-users.log') : STDOUT))
    @logger = logger
  end

  def perform
    return unless Setting.find_by_name(:plugin_redmine_2chat).value['kick_locked']
    client.on_ready(&method(:kick_locked_users))
  end

  private

  def kick_locked_users(client)
    IssueChat.where(platform_name: 'telegram').all.each do |group|
      chat = client.broadcast_and_receive('@type' => 'getChat', 'chat_id' => group.im_id)

      group_info = client.broadcast_and_receive('@type' => 'getBasicGroupFullInfo',
                                     'basic_group_id' => chat.dig('type', 'basic_group_id')
      )
      (@logger.warn("Error while fetching group ##{group.im_id}: #{group_info.inspect}") && next) if group_info['@type'] == 'error'

      telegram_user_ids = group_info['members'].map { |m| m['user_id'] }

      TelegramAccount.preload(:user).where(telegram_id: telegram_user_ids).each do |account|
        user = account.user
        next unless user&.locked?
        result = client.broadcast_and_receive('@type' => 'setChatMemberStatus',
                                    'chat_id' => group.im_id,
                                    'user_id' => account.telegram_id,
                                    'status' => { '@type' => 'chatMemberStatusLeft' })
        @logger.info("Kicked user ##{user.id} from chat ##{group.im_id}") if result['@type'] == 'ok'
        @logger.error("Failed to kick user ##{user.id} from chat ##{group.im_id}: #{result.inspect}") if result['@type'] == 'error'
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
