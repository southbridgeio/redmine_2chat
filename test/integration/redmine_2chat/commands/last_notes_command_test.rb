require File.expand_path('../../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class Redmine2chat::Telegram::Commands::LastIssuesNotesCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :journals

  let(:command) do
    Telegram::Bot::Types::Message.new(
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today.to_time.to_i,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' },
      text: '/last')
  end

  let(:user) { User.find(1) }
  let(:url_base) { "#{Setting.protocol}://#{Setting.host_name}" }

  before do
    TelegramAccount.create(telegram_id: command.from.id, user_id: user.id)
    Issue.update_all(project_id: 1)
    Issue.where.not(id: [1, 5]).destroy_all
  end

  let(:issue_journal_time) { I18n.l Issue.find(1).journals.last.created_on, format: :long }
  it 'sends last five updated issues with journals' do
    text = "<a href=\"#{url_base}/issues/1\">#1</a>: Cannot print recipes <pre>Some notes with Redmine links: #2, r2.</pre> <i>#{issue_journal_time}</i>\n\n<a href=\"#{url_base}/issues/5\">#5</a>: Subproject issue <pre>New issue</pre>\n\n"

    Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
      .expects(:send_message)
      .with(text)

    Redmine2chat::Telegram::Commands::LastIssuesNotesCommand.new(command).execute
  end

  it 'escapes html tags in journals' do
    Issue.find(1).journals.last.update(notes: '<pre>Note with tags.</pre> Some text.')
    text = "<a href=\"#{url_base}/issues/1\">#1</a>: Cannot print recipes <pre>Note with tags. Some text.</pre> <i>#{issue_journal_time}</i>\n\n<a href=\"#{url_base}/issues/5\">#5</a>: Subproject issue <pre>New issue</pre>\n\n"
    Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
      .expects(:send_message)
      .with(text)

    Redmine2chat::Telegram::Commands::LastIssuesNotesCommand.new(command).execute
  end
end
