module Redmine2chat::Telegram::Tdlib
  class KickLockedUsers < RedmineBots::Telegram::Tdlib::Command
    def call
      ActiveRecord::Base.connection_pool.with_connection do
        telegram_accounts = TelegramAccount.where.not(telegram_id: nil)
                                           .joins(:user)
                                           .preload(:user)
                                           .where(users: { status: Principal::STATUS_LOCKED })
                                           .to_a

        message_senders = telegram_accounts.map do |telegram_account|
          TD::Types::MessageSender::User.new(user_id: telegram_account.telegram_id)
        end

        promises = IssueChat.active.where(platform_name: 'telegram').where.not(im_id: nil).map do |group|
          client.get_chat(chat_id: group.im_id).then do |chat|
            case chat.type
            when TD::Types::ChatType::Supergroup
              client.get_supergroup_members(supergroup_id: chat.type.supergroup_id, filter: nil, offset: 0, limit: 100)
            when TD::Types::ChatType::BasicGroup
              client.get_basic_group_full_info(basic_group_id: chat.type.basic_group_id)
            else
              # do nothing
            end
          end.flat.rescue { nil }.then do |group_info|
            next Promises.fulfilled_future(true) if group_info.blank?

            accounts = message_senders.select { |account| account.in?(group_info.members.map(&:member_id)) }
            Promises.zip(*accounts.map { |account| kick_member(group.im_id, account) })
          end.flat
        end

        Promises.zip(*promises)
      end
    end

    private

    def kick_member(chat_id, member_id)
      client.set_chat_member_status(chat_id: chat_id, member_id: member_id, status: ChatMemberStatus::Left.new).rescue { nil }
    end
  end
end
