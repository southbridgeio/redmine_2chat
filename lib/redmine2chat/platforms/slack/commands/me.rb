class Redmine2chat::Platforms::Slack
  module Commands
    class Me < RedmineBots::Slack::Commands::Base
      private_only
      responds_to :me

      def self.description
        I18n.t('redmine_2chat.bot.private.help.me')
      end

      def call
        client.web_client.chat_postMessage(channel: data.channel, text: I18n.t('redmine_2chat.bot.me'), attachments: attachments)
      end

      protected

      def authorized?
        current_user.logged?
      end

      def attachments
        issues.map { |issue| { text: "<#{issue_url(issue)}|##{issue.id}>: #{issue.subject}" } }
      end

      def issues
        Issue.open.where(assigned_to_id: current_user.id)
      end

      def issue_url(issue)
        Rails.application.routes.url_helpers.issue_url(
            issue,
            host: Setting.host_name,
            protocol: Setting.protocol)
      end
    end
  end
end
