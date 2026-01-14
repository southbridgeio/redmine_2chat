log_dir = Rails.root.join('log/redmine_2chat')
tmp_dir = Rails.root.join('tmp/redmine_2chat')

FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
FileUtils.mkdir_p(tmp_dir) unless Dir.exist?(tmp_dir)

require_dependency Rails.root.join('plugins','redmine_bots', 'init')
require 'dry/monads/result'

register_after_redmine_initialize_proc =
  if Redmine::VERSION::MAJOR >= 5
    Rails.application.config.public_method(:after_initialize)
  else
    reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
    reloader.public_method(:to_prepare)
  end
register_after_redmine_initialize_proc.call do
  paths = '/lib/redmine2chat/{patches/*_patch,hooks/*_hook,operations/*}.rb'

  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end

  Redmine2chat.register_platform('slack', Redmine2chat::Platforms::Slack.new)
  Redmine2chat.register_platform('telegram', Redmine2chat::Platforms::Telegram.new)

  RedmineBots::Slack::Bot.register_handlers Redmine2chat::Platforms::Slack::MessageHandler

  RedmineBots::Slack::Bot.register_commands Redmine2chat::Platforms::Slack::Commands::Me,
                                            Redmine2chat::Platforms::Slack::Commands::Spent,
                                            Redmine2chat::Platforms::Slack::Commands::Yspent

  %w[new hot me deadline dl spent yspent last chat task issue ih th become_chat_admin].each do |command|
    RedmineBots::Telegram.bot.register_handler(Redmine2chat::Telegram::Handlers::PrivateLegacyCommand.new(command))
  end

  %w[task link url log subject start_date due_date estimated_hours done_ratio project tracker status priority assigned_to subject_chat].each do |command|
    RedmineBots::Telegram.bot.register_handler(Redmine2chat::Telegram::Handlers::GroupLegacyCommand.new(command))
  end

  RedmineBots::Telegram.bot.register_handler(Redmine2chat::Telegram::Handlers::ChatMessageHandler.new)

  RedmineBots::Telegram.bot.register_persistent_command(TelegramExecutingCommand)
end

Rails.application.config.eager_load_paths += Dir.glob("#{Rails.application.config.root}/plugins/redmine_2chat/{lib,app/workers,app/models,app/controllers}")

Sidekiq::Cron::Job.create(name:  'Issue chats Auto Close - every 1 hour',
                          cron:  '7 * * * *',
                          class: 'IssueChatAutoCloseWorker')

Sidekiq::Cron::Job.create(name:  'Issue chats Daily Report - every day',
                          cron:  '7 0 * * *',
                          class: 'IssueChatDailyReportCronWorker')

Sidekiq::Cron::Job.create(name:  'Issue chats Kick locked users - every day',
                          cron:  '7 0 * * *',
                          class: 'IssueChatKickLockedUsersWorker')

Redmine::Plugin.register :redmine_2chat do
  name 'Redmine 2Chat'
  url 'https://github.com/southbridgeio/redmine_2chat'
  description 'This is a plugin for Redmine which adds group chats to Redmine issues on different chat platforms such as Slack and Telegram.'
  version '0.5.0'
  author 'Southbridge'
  author_url 'https://github.com/southbridgeio'

  requires_redmine_plugin :redmine_bots, '0.5.0'

  settings(default: {
             'daily_report' => '1',
             'kick_locked' => '1',
             'active_platform' => 'telegram'
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

# Eager load throttled workers for Sidekiq Web UI
Rails.application.config.after_initialize do
  require_dependency 'issue_chat_message_sender_worker' rescue nil
end
