module Redmine2chat::Platforms
  class Slack
    include Dry::Monads::Result::Mixin

    def create_chat(title, issue)
      channel = robot_client.channels_create(name: title).channel
      team = robot_client.team_info.team
      bot_id = bot_client.auth_test.user_id

      robot_client.channels_invite(channel: channel.id, user: bot_id)

      Success({ im_id: channel.id, chat_url: "slack://channel?id=#{channel.id}&team=#{team.id}" })
    end

    def close_chat(im_id, message)
      robot_client.chat_postMessage(channel: im_id, text: message)
      robot_client.channels_archive(channel: im_id)

      Success(true)
    end

    def send_message(im_id, message, **)
      robot_client.chat_postMessage(channel: im_id, text: message)
    end

    def icon_path
      '/plugin_assets/redmine_2chat/images/slack-icon.png'
    end

    def inactive_icon_path
      '/plugin_assets/redmine_2chat/images/slack-inactive-icon.png'
    end

    private

    def robot_client
      @robot_client ||= RedmineBots::Slack.robot_client
    end

    def bot_client
      @bot_client ||= RedmineBots::Slack.bot_client
    end
  end
end
