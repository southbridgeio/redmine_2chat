module Redmine2chat::Platforms
  class Yandex < Base
    module Log
      PATH = Rails.root.join('log', 'redmine_2chat', 'yandex.log').freeze

      class << self
        attr_writer :logger

        def logger
          @logger ||= ::Logger.new(PATH)
        end

        def info(message, **context)
          write(:info, message, **context)
        end

        def warn(message, **context)
          write(:warn, message, **context)
        end

        def error(message, **context)
          write(:error, message, **context)
        end

        private

        def write(level, message, issue: nil, chat: nil)
          logger.public_send(level, [prefix(issue, chat), message].compact.join(' '))
        rescue StandardError => e
          Rails.logger.error("redmine_2chat: unable to write #{PATH}: #{e.message}")
        end

        def prefix(issue, chat)
          parts = []
          parts << "issue ##{issue.id}" if issue
          parts << "chat #{chat}" if chat.present?

          "#{parts.join(' ')}:" if parts.any?
        end
      end
    end
  end
end
