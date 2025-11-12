class IssueChatMessageSenderWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :issue_chats

  sidekiq_throttle(
    threshold: { limit: 15, period: 1.second }
  )

  def perform(im_id, platform_name, message, params = {})
    Redmine2chat.platforms[platform_name].send_message(im_id, message, params.symbolize_keys)
  end
end
