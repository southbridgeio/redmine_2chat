module Redmine2chat::Telegram
  module LegacyCommands
    class FindIssuesCommand < BaseBotCommand
      LOGGER = Logger.new(Rails.root.join('log/redmine_2chat', 'bot-command-find-issues.log'))
      ISSUES_PER_MESSAGE = 20

      def execute
        return unless account.present?
        if issues.count > 0
          issues.each_slice(ISSUES_PER_MESSAGE).with_index do |issues_chunk, index|
            send_message(issues_list(issues_chunk, with_title: index.zero?))
          end
        else
          issues_not_found = I18n.t('redmine_2chat.bot.issues_not_found')
          send_message(issues_not_found)
        end
      end

      private

      def command_name
        case command.text
        when %r{/hot}
          'hot'
        when %r{/me}
          'me'
        when %r{/deadline|/dl}
          'deadline'
        else
          'me'
        end
      end

      def message
        @message ||= I18n.t("redmine_2chat.bot.#{command_name}")
      end

      def issues
        @issues ||= issue_filters[command_name]
      end

      def issue_filters
        assigned_to_me = Issue.joins(:project).open
                         .where(projects: { status: 1 })
                         .where(assigned_to: account.user)
        {
          'me' => assigned_to_me,
          'hot' => assigned_to_me.where('issues.updated_on >= ?', 24.hours.ago),
          'deadline' => assigned_to_me.where('due_date < ?', Date.today)
        }
      end

      def issues_list(issues, with_title: false)
        message_title = with_title ? "<b>#{message}:</b>\n" : ''
        issues.inject(message_title) do |message_text, issue|
          url = issue_url(issue)
          message_text << %(<a href="#{url}">##{issue.id}</a>: #{CGI::escapeHTML(issue.subject)}\n)
        end
      end
    end
  end
end
