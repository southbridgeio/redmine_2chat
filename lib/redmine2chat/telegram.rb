module Redmine2chat
  module Telegram
    def self.issue_url(issue_id)
      url = Addressable::URI.parse("#{Setting['protocol']}://#{Setting['host_name']}/issues/#{issue_id}")
      url.to_s
    end
  end
end