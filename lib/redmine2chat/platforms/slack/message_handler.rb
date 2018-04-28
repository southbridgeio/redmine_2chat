class Redmine2chat::Platforms::Slack
  class MessageHandler < RedmineBots::Slack::EventHandler
    def self.event
      'message'
    end

    def initialize(client, data)
      super
      @issue_chat = IssueChat.find_by(im_id: data.channel, platform_name: 'slack')
      @user_info = client.web_client.users_info(user: data.user)
    end

    def call
      return unless @issue_chat

      @issue_chat.messages.create!(
          message: data.text,
          im_id: data.user,
          username: @user_info.user.profile.real_name,
          sent_at: Time.now
      )
    end
  end
end
