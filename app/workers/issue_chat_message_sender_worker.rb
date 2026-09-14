class IssueChatMessageSenderWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :issue_chats

  sidekiq_throttle(
    threshold: { limit: 15, period: 1.second }
  )

  def perform(im_id, platform_name, message, params = {})
    platform = Redmine2chat.platform(platform_name)

    if platform.nil?
      raise "redmine_2chat: chat platform #{platform_name.inspect} is not registered in this process " \
            "(registered: #{Redmine2chat.platforms.keys.inspect}); restart the worker"
    end

    platform.send_message(im_id, message, params.symbolize_keys)
  end
end
