class Redmine2chat::Platforms::Slack
  module Commands
    class Yspent < Spent
      responds_to :yspent

      def self.description
        I18n.t('redmine_2chat.bot.private.help.yspent')
      end

      protected

      def date
        Date.yesterday
      end
    end
  end
end
