namespace :redmine_2chat do
  task migrate_from_chat_telegram: :environment do
    class TelegramCommonAccount < ActiveRecord::Base
    end

    class TelegramMessage < ActiveRecord::Base
    end

    class RedmineChatTelegramTelegramGroup < ActiveRecord::Base
      belongs_to :issue
    end

    Issue.send(:include,
               Module.new do
                 def self.included(klass)
                   klass.send(:has_many, :telegram_messages)
                   klass.send(:has_one, :redmine_chat_telegram_telegram_group)
                 end
               end
    )

    Issue.transaction do
      Issue.joins(:telegram_messages).preload(:telegram_messages, :redmine_chat_telegram_telegram_group).distinct.each do |issue|
        puts "Transfering telegram chat for issue ##{issue.id}..."

        chat = issue.chats.create!(
            platform_name: 'telegram',
            im_id: issue.redmine_chat_telegram_telegram_group&.telegram_id,
            shared_url: issue.redmine_chat_telegram_telegram_group&.shared_url,
            need_to_close_at: issue.redmine_chat_telegram_telegram_group&.need_to_close_at,
            last_notification_at: issue.redmine_chat_telegram_telegram_group&.last_notification_at,
            active: issue.redmine_chat_telegram_telegram_group.present?
        )

        issue.telegram_messages.each do |message|
          ChatMessage.create!(
              issue_chat_id: chat.id,
              im_id: message.telegram_id,
              user_id: TelegramCommonAccount.find_by(telegram_id: message.from_id)&.user_id,
              first_name: message.from_first_name,
              last_name: message.from_last_name,
              username: message.from_username,
              sent_at: message.sent_at,
              message: message.message,
              system_data: message.system_data,
              is_system: message.is_system
          )
        end
      end

      Sidekiq::Cron::Job.destroy('Telegram Group Auto Close - every 1 hour')
      Sidekiq::Cron::Job.destroy('Telegram Group Daily Report - every day')
      Sidekiq::Cron::Job.destroy('Telegram Kick locked users - every day')
    end
  end
end
