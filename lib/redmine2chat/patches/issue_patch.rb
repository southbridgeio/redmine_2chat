module Redmine2chat::Patches
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        has_many :chats, class_name: 'IssueChat'
        has_many :chat_messages, through: :chats, source: :messages
        has_many :active_chats, -> { active }, class_name: 'IssueChat'
        has_one :active_chat, -> { active }, class_name: 'IssueChat'

        before_save :set_need_to_close_and_notify, :reset_need_to_close

        def active_chat_for(platform_name)
          active_chats.detect { |chat| chat.platform_name == platform_name.to_s }
        end

        def set_need_to_close_and_notify
          return unless active_chats.any?

          if closing_with_active_chat? || (was_closed? && status_was_not_in_settings?)
            active_chats.each do |chat|
              chat.update need_to_close_at: 1.week.from_now,
                          last_notification_at: 4.days.from_now,
                          close_attempts: 0
            end

            # Delay for the data to be saved in the database
            IssueChatCloseNotificationWorker.perform_in(5.seconds, id)
          end
        end

        def reset_need_to_close
          return unless active_chats.any?

          if reopening? || (was_closed? && status_was_in_settings?)
            active_chats.each do |chat|
              chat.update need_to_close_at: nil, last_notification_at: nil, close_attempts: 0
            end
          end
        end

        private

        def closing_with_active_chat?
          closing? && close_issue_status_ids.include?(status_id.to_s)
        end

        def status_was_in_settings?
          close_issue_status_ids.include?(status_was.id.to_s) && !close_issue_status_ids.include?(status_id.to_s)
        end

        def status_was_not_in_settings?
          !close_issue_status_ids.include?(status_was.id.to_s) && close_issue_status_ids.include?(status_id.to_s)
        end

        def close_issue_status_ids
          @close_issue_status_ids ||= Array(Setting['plugin_redmine_2chat']['close_issue_statuses'])
        end
      end
    end
  end
end

Issue.send(:include, Redmine2chat::Patches::IssuePatch)
