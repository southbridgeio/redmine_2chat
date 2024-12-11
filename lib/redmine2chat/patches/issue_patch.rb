module Redmine2chat::Patches
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        has_many :chats, class_name: 'IssueChat'
        has_many :chat_messages, through: :chats, source: :messages
        has_one :active_chat, -> { active }, class_name: 'IssueChat'

        before_save :set_need_to_close_and_notify, :reset_need_to_close

        def set_need_to_close_and_notify
          if is_closing_with_active_chat? || (was_closed_with_active_chat? && status_was_not_in_settings?)
            active_chat.update need_to_close_at: 1.week.from_now,
                        last_notification_at: 4.days.from_now

            # Delay for the data to be saved in the database
            IssueChatCloseNotificationWorker.perform_in(5.seconds, id)
          end
        end

        def reset_need_to_close
          if (reopening? && active_chat.present?) || (was_closed_with_active_chat? && status_was_in_settings?)
            active_chat.update need_to_close_at: nil,
                        last_notification_at: nil
          end
        end

        private

        def is_closing_with_active_chat?
          closing? && active_chat.present? && close_issue_status_ids.include?(status_id.to_s)
        end

        def was_closed_with_active_chat?
          was_closed? && active_chat.present?
        end

        def status_was_in_settings?
          close_issue_status_ids.include?(status_was.id.to_s) && !close_issue_status_ids.include?(status_id.to_s)
        end

        def status_was_not_in_settings?
          !close_issue_status_ids.include?(status_was.id.to_s) && close_issue_status_ids.include?(status_id.to_s)
        end

        def close_issue_status_ids
          @close_issue_status_ids ||= Setting['plugin_redmine_2chat']['close_issue_statuses']
        end
      end
    end
  end
end

Issue.send(:include, Redmine2chat::Patches::IssuePatch)
