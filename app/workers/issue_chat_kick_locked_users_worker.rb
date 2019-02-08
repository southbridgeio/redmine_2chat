class IssueChatKickLockedUsersWorker
  include Sidekiq::Worker

  def perform
    return unless Setting.find_by_name(:plugin_redmine_2chat).value['kick_locked']
    Redmine2chat::Telegram::Tdlib::KickLockedUsers.call.wait!
  end
end
