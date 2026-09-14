require File.expand_path('../../../test_helper', __FILE__)

class Redmine2chat::Operations::CreateChatTest < ActiveSupport::TestCase
  include Dry::Monads::Result::Mixin

  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :journals, :email_addresses, :enabled_modules

  let(:issue) { Issue.find(1) }

  class FakePlatform < Redmine2chat::Platforms::Base
    def initialize(im_id)
      @im_id = im_id
    end

    def available?
      true
    end

    def create_chat(_title, _issue)
      Success(im_id: @im_id, chat_url: "https://example.org/#{@im_id}")
    end

    def close_chat(_im_id, _message)
      Success(true)
    end

    def send_message(*); end
  end

  # Never confirms a close — stands in for a bot kicked out of the chat.
  class UnclosablePlatform < FakePlatform
    def close_chat(_im_id, _message)
      Failure('Bot is not a member of the chat')
    end
  end

  before do
    Redmine2chat.register_platform('fake_one', FakePlatform.new('one'))
    Redmine2chat.register_platform('fake_two', FakePlatform.new('two'))
    Setting.plugin_redmine_2chat = Setting.plugin_redmine_2chat.merge('active_platforms' => %w[fake_one fake_two])
    User.current = User.find(1)
  end

  after do
    Redmine2chat.platforms.delete('fake_one')
    Redmine2chat.platforms.delete('fake_two')
    User.current = nil
  end

  it 'stores the chat under the requested platform' do
    assert Redmine2chat::Operations::CreateChat.(issue, 'fake_one').success?

    chat = issue.reload.active_chat_for('fake_one')
    assert_equal 'one', chat.im_id
    assert_equal 'fake_one', chat.platform_name
  end

  it 'keeps one active chat per platform on the same issue' do
    Redmine2chat::Operations::CreateChat.(issue, 'fake_one')
    Redmine2chat::Operations::CreateChat.(issue, 'fake_two')

    assert_equal %w[fake_one fake_two], issue.reload.active_chats.map(&:platform_name).sort
  end

  it 'refuses a platform that is not enabled' do
    Setting.plugin_redmine_2chat = Setting.plugin_redmine_2chat.merge('active_platforms' => %w[fake_one])

    result = Redmine2chat::Operations::CreateChat.(issue, 'fake_two')

    assert result.failure?
    assert_nil issue.reload.active_chat_for('fake_two')
  end

  it 'refuses an unknown platform' do
    assert Redmine2chat::Operations::CreateChat.(issue, 'nope').failure?
  end

  it 'closes only the requested platform' do
    Redmine2chat::Operations::CreateChat.(issue, 'fake_one')
    Redmine2chat::Operations::CreateChat.(issue, 'fake_two')

    assert Redmine2chat::Operations::CloseChat.(issue.reload, 'fake_one').success?

    issue.reload
    assert_nil issue.active_chat_for('fake_one')
    assert issue.active_chat_for('fake_two').present?
  end

  it 'falls back to the legacy active_platform setting' do
    Setting.plugin_redmine_2chat = Setting.plugin_redmine_2chat
                                          .except('active_platforms')
                                          .merge('active_platform' => 'fake_one')

    assert_equal %w[fake_one], Redmine2chat.active_platform_names
    assert Redmine2chat::Operations::CreateChat.(issue).success?
    assert_equal 'one', issue.reload.active_chat_for('fake_one').im_id
  end
end

class Redmine2chat::Operations::CloseChatTest < ActiveSupport::TestCase
  include Dry::Monads::Result::Mixin

  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :journals, :email_addresses, :enabled_modules

  let(:issue) { Issue.find(1) }
  let(:platform) { Redmine2chat::Operations::CreateChatTest::UnclosablePlatform.new('one') }

  before do
    Redmine2chat.register_platform('unclosable', platform)
    Setting.plugin_redmine_2chat = Setting.plugin_redmine_2chat.merge('active_platforms' => %w[unclosable])
    User.current = User.find(1)
    @chat = issue.chats.create!(im_id: 'x1', shared_url: 'https://example.org/x1', platform_name: 'unclosable')
  end

  after do
    Redmine2chat.platforms.delete('unclosable')
    User.current = nil
  end

  def close
    Redmine2chat::Operations::CloseChat.(issue.reload, 'unclosable')
  end

  it 'keeps the chat open and counts the attempt while the platform may still recover' do
    result = close

    assert result.failure?
    assert_equal 1, @chat.reload.close_attempts
    assert @chat.active?
  end

  it 'gives up after MAX_ATTEMPTS and closes the chat in Redmine alone' do
    (Redmine2chat::Operations::CloseChat::MAX_ATTEMPTS - 1).times { close }

    assert issue.reload.active_chat_for('unclosable').present?

    result = close

    assert result.failure?
    refute @chat.reload.active?
    assert_nil issue.reload.active_chat_for('unclosable')
  end

  it 'explains in the issue journal that only Redmine closed it' do
    Redmine2chat::Operations::CloseChat::MAX_ATTEMPTS.times { close }

    notes = issue.reload.journals.last.notes

    assert_includes notes, 'Bot is not a member of the chat'
    assert_includes notes, Redmine2chat::Operations::CloseChat::MAX_ATTEMPTS.to_s
  end

  it 'starts the count over when the issue is reopened' do
    issue.reload.update!(status_id: IssueStatus.where(is_closed: true).first.id)

    2.times { close }
    assert_equal 2, @chat.reload.close_attempts

    issue.reload.update!(status_id: IssueStatus.where(is_closed: false).first.id)

    assert_equal 0, @chat.reload.close_attempts
  end
end
