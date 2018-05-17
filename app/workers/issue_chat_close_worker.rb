class IssueChatCloseWorker
  include Sidekiq::Worker

  def perform(im_id, platform_name, user_id = nil)
    platform = Redmine2chat.platforms[platform_name]
    user = User.find_by_id(user_id) || User.anonymous
    message = I18n.t("redmine_2chat.messages.closed_#{user.anonymous? ? 'automatically' : 'from_issue'}")
    platform.close_chat(im_id, message)
  end
end
