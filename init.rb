require 'redmine_2chat'

# Rails 5.1/Rails 4
reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
reloader.to_prepare do
  paths = '/lib/redmine_2chat/{patches/*_patch,hooks/*_hook,platforms/*}.rb'

  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end

  Redmine2chat.register_platform('slack', Redmine2chat::Platforms::Slack.new)
  Redmine2chat.register_platform('telegram', Redmine2chat::Platforms::Telegram.new)
end

Redmine::Plugin.register :redmine_2chat do
  name 'Redmine 2Chat'
  url 'https://github.com/centosadmin/redmine_2chat'
  description 'This is a plugin for Redmine which adds group chats to Redmine issues on different chat platforms such as Slack and Telegram.'
  version '0.1.0'
  author 'Southbridge'
  author_url 'https://github.com/centosadmin'

  # requires_redmine_plugin :redmine_telegram_common, '0.7.0'

  settings(default: {
             'daily_report' => '1',
             'kick_locked' => '1'
           },
           partial: 'settings/redmine_2chat')

  project_module :redmine_2chat do
    permission :create_chat,       issue_chats: :create
    permission :close_chat,        issue_chats: :destroy
    permission :view_chat_link,    issue_chats: :create
    permission :view_chat_archive, issue_chats: :create
    permission :manage_chat,       issue_chats: :edit
  end
end