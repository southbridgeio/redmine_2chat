require_dependency 'telegram_account'

module Redmine2chat::Telegram::Tdlib
  class KickLockedUsers < RedmineBots::Telegram::Tdlib::Command
    def call
      promises = IssueChat.where(platform_name: 'telegram').where.not(im_id: nil).map do |group|
        client.get_chat(group.im_id).then do |chat|
          client.get_basic_group_full_info(chat.type.basic_group_id)
        end.flat.then do |group_info|
          accounts = TelegramAccount.preload(:user)
                         .joins(:user)
                         .where(telegram_id: group_info.members.map(&:user_id))
                         .where(users: { status: Principal::STATUS_LOCKED })
          Promises.zip(*accounts.map { |account| kick_member(group.im_id, account.telegram_id) })
        end.flat
      end

      Promises.zip(*promises)
    end

    private

    def kick_member(chat_id, user_id)
      client.set_chat_member_status(chat_id, user_id, ChatMemberStatus::Left.new)
    end
  end
end
