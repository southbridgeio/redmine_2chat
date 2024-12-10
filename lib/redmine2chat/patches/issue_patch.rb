module Redmine2chat::Patches
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        has_many :chats, class_name: 'IssueChat'
        has_many :chat_messages, through: :chats, source: :messages
        has_one :active_chat, -> { active }, class_name: 'IssueChat'

        before_save :set_need_to_close_and_notify, :reset_need_to_close

        def set_need_to_close_and_notify
          if closing? && active_chat.present?
            active_chat.update need_to_close_at: 1.week.from_now,
                        last_notification_at: 4.days.from_now

            # Delay for the data to be saved in the database
            IssueChatCloseNotificationWorker.perform_in(5.seconds, id)
          end
        end

        def reset_need_to_close
          if reopening? && active_chat.present?
            active_chat.update need_to_close_at: nil,
                        last_notification_at: nil
          end
        end
      end
    end
  end
end
Issue.send(:include, Redmine2chat::Patches::IssuePatch)
