class Redmine2chat::Platforms::Slack
  module Commands
    class Spent < RedmineBots::Slack::Commands::Base
      private_only
      responds_to :spent

      def self.description
        I18n.t('redmine_2chat.bot.private.help.spent')
      end

      def call
        reply(text: text)
      end

      protected

      def authorized?
        current_user.logged?
      end

      def text
        I18n.t("redmine_2chat.bot.#{self.class.name.demodulize.underscore}", hours: spent_hours)
      end

      def spent_hours
        TimeEntry.where(spent_on: date, user: current_user).sum(:hours).round(2)
      end

      def date
        Date.today
      end
    end
  end
end
