require_dependency 'telegram_account'

module Redmine2chat::Telegram::Tdlib
  class KickLockedUsers < RedmineBots::Telegram::Tdlib::Command
    def call
      ActiveRecord::Base.connection_pool.with_connection do
        telegram_accounts = TelegramAccount.where.not(telegram_id: nil)
                                           .joins(:user)
                                           .preload(:user)
                                           .where(users: { status: Principal::STATUS_LOCKED })
                                           .to_a

        promises = IssueChat.active.where(platform_name: 'telegram').where.not(im_id: nil).map do |group|
          client.get_chat(group.im_id).then do |chat|
            client.get_basic_group_full_info(chat.type.basic_group_id)
          end.flat.rescue { nil }.then do |group_info|
            next Promises.fulfilled_future(true) if group_info.blank?

            accounts = telegram_accounts.select { |account| account.telegram_id.in?(group_info.members.map(&:user_id)) }
            Promises.zip(*accounts.map { |account| kick_member(group.im_id, account.telegram_id) })
          end.flat
        end

        Promises.zip(*promises)
      end
    end

    private

    def kick_member(chat_id, user_id)
      client.set_chat_member_status(chat_id, user_id, ChatMemberStatus::Left.new).rescue { nil }
    end
  end
end
