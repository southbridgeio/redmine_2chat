module Redmine2chat::Platforms
  class Yandex < Base
    # Notification texts across the plugin are built as Telegram-flavoured HTML
    # (<b>, <i>, <pre>, <a href>). Yandex Messenger expects its own
    # markdown-like syntax instead, so the markup is translated here.
    #
    # https://yandex.ru/dev/messenger/doc/ru/formatting
    module TextFormatter
      module_function

      def call(text)
        return '' if text.blank?

        result = text.to_s.dup
        result.gsub!(%r{<br\s*/?>}i, "\n")
        result.gsub!(%r{</p>}i, "\n")
        result.gsub!(%r{<pre[^>]*>(.*?)</pre>}mi) { "\n```\n#{strip_tags(Regexp.last_match(1)).strip}\n```\n" }
        result.gsub!(%r{<code[^>]*>(.*?)</code>}mi) { "`#{strip_tags(Regexp.last_match(1))}`" }
        result.gsub!(%r{<a[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>}mi) do
          "[#{strip_tags(Regexp.last_match(2))}](#{Regexp.last_match(1)})"
        end
        result.gsub!(%r{<(b|strong)[^>]*>(.*?)</\1>}mi) { "**#{strip_tags(Regexp.last_match(2))}**" }
        result.gsub!(%r{<(i|em)[^>]*>(.*?)</\1>}mi) { "__#{strip_tags(Regexp.last_match(2))}__" }
        result.gsub!(%r{<(s|strike|del)[^>]*>(.*?)</\1>}mi) { "~~#{strip_tags(Regexp.last_match(2))}~~" }
        result.gsub!(%r{<u[^>]*>(.*?)</u>}mi) { "++#{strip_tags(Regexp.last_match(1))}++" }

        unescape(strip_tags(result)).strip
      end

      def strip_tags(text)
        text.to_s.gsub(/<[^>]*>/, '')
      end

      def unescape(text)
        CGI.unescapeHTML(text.to_s)
      end
    end
  end
end
