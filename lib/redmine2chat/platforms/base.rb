module Redmine2chat::Platforms
  class Base
    include Dry::Monads::Result::Mixin

    def self.platform_name
      name.demodulize.underscore
    end

    def platform_name
      self.class.platform_name
    end

    def create_chat(_title, _issue)
      raise NotImplementedError
    end

    def close_chat(_im_id, _message)
      raise NotImplementedError
    end

    def send_message(_im_id, _message, _params = {})
      raise NotImplementedError
    end

    def available?
      true
    end

    def icon_path
      "plugin_assets/redmine_2chat/#{platform_name}-icon.png"
    end

    def inactive_icon_path
      "plugin_assets/redmine_2chat/#{platform_name}-inactive-icon.png"
    end

    def title
      platform_name.titleize
    end
  end
end
