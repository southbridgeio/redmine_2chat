class IssueChatMessageSenderWorker
  include Sidekiq::Worker
  sidekiq_options queue: :issue_chats,
                  rate:  {
                    name:   'issue_chats_rate_limit',
                    limit:  15,
                    period: 1
                  }

  def perform(im_id, platform_name, message)
    Redmine2chat.platforms[platform_name].send_message(im_id, message)
  end
end
