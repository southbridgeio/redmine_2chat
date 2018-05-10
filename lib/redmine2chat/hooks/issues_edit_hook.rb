module Redmine2chat
  module Hooks
    class IssuesEditHook < Redmine::Hook::ViewListener
      def controller_issues_edit_after_save(context = {})
        return if context[:journal].private_notes

        issue = context[:issue]

        return unless issue_chat = issue.active_chat

        IssueChatNotificationsWorker.perform_async(issue_chat.im_id, issue_chat.platform_name, context[:journal].id)
      end
    end
  end
end
