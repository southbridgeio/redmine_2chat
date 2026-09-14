require File.expand_path('../../../test_helper', __FILE__)

class Redmine2chat::Platforms::YandexTest < ActiveSupport::TestCase
  include Dry::Monads::Result::Mixin

  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :email_addresses, :enabled_modules,
           :roles, :members, :member_roles

  let(:issue) { Issue.find(1) }
  let(:user) { User.find(2) }
  let(:platform) { Redmine2chat::Platforms::Yandex.new }

  # Records the calls instead of hitting botapi.messenger.yandex.net.
  class FakeClient
    attr_reader :calls

    def initialize(members: [], known: :all)
      @calls = []
      @members = members
      @known = known
    end

    def find_user(login)
      @calls << [:find_user, login]
      return "guid-#{login}" if @known == :all || Array(@known).include?(login)

      nil
    end

    def create_chat(**params)
      @calls << [:create_chat, params]
      { 'ok' => true, 'chat_id' => '0/0/abc', 'invite_link' => 'https://yandex.ru/chat/#/join/xyz' }
    end

    def send_text(**params)
      @calls << [:send_text, params]
      { 'ok' => true, 'message_id' => 1 }
    end

    def chat_members(chat_id)
      @calls << [:chat_members, chat_id]
      @members
    end

    def update_members(**params)
      @calls << [:update_members, params]
      { 'ok' => true }
    end

    def call_params(name)
      @calls.detect { |c| c.first == name }&.last
    end
  end

  before do
    Setting.plugin_redmine_bots = Setting.plugin_redmine_bots.merge('yandex_bot_token' => 'AtTEST')
    set_login(user, 'user2@example.org')
    User.current = user
  end

  after do
    User.current = nil
  end

  def set_login(a_user, login)
    a_user.yandex_login = login
    a_user.save!
    a_user.reload
  end

  def stub_client(client)
    platform.define_singleton_method(:client) { client }
  end

  # Swaps the Yandex log for an in-memory one and returns the lines written.
  def capture_log
    io = StringIO.new
    previous = Redmine2chat::Platforms::Yandex::Log.logger
    Redmine2chat::Platforms::Yandex::Log.logger = Logger.new(io)
    yield
    io.string.lines.map(&:chomp).reject { |l| l.empty? || l.start_with?('#') }
  ensure
    Redmine2chat::Platforms::Yandex::Log.logger = previous
  end

  it 'is unavailable without a bot token' do
    Setting.plugin_redmine_bots = Setting.plugin_redmine_bots.merge('yandex_bot_token' => '')

    refute platform.available?
    assert platform.create_chat('Title', issue).failure?
  end

  it 'creates a chat and returns a link to it' do
    client = FakeClient.new
    stub_client(client)

    result = platform.create_chat('Project 1', issue)

    assert result.success?
    assert_equal '0/0/abc', result.value![:im_id]
    assert_equal 'https://yandex.ru/chat/#/join/xyz', result.value![:chat_url]

    params = client.call_params(:create_chat)
    assert_equal 'Project 1', params[:name]
    assert params[:public], 'chat must be public, otherwise the API returns no invite link'
    assert_includes (params[:admins] + params[:members]), 'user2@example.org'
  end

  it 'falls back to a deep link when the API returns no invite link' do
    client = FakeClient.new
    client.define_singleton_method(:create_chat) { |**| { 'ok' => true, 'chat_id' => '0/0/abc' } }
    stub_client(client)

    result = platform.create_chat('Project 1', issue)

    assert_equal RedmineBots::Yandex.web_chat_url('0/0/abc'), result.value![:chat_url]
  end

  it 'refuses to create a chat when the creator has no Yandex login' do
    set_login(user, '')
    stub_client(FakeClient.new)

    result = platform.create_chat('Project 1', issue)

    assert result.failure?
    assert_equal I18n.t('redmine_2chat.yandex.errors.creator_not_linked'), result.failure
  end

  it 'never falls back to the Redmine e-mail' do
    set_login(user, '')

    assert_nil RedmineBots::Yandex.login_for(user)
    assert user.mail.present?
  end

  it 'leaves out participants who have no login yet' do
    client = FakeClient.new
    stub_client(client)
    issue.update_columns(assigned_to_id: User.find(3).id)

    platform.create_chat('Project 1', issue)

    params = client.call_params(:create_chat)
    logins = params[:admins] + params[:members]
    assert_equal ['user2@example.org'], logins
  end

  it 'records every participant it had to leave out' do
    client = FakeClient.new
    stub_client(client)
    issue.update_columns(assigned_to_id: User.find(3).id)

    logged = capture_log { platform.create_chat('Project 1', issue) }
    skipped = logged.grep(/не добавлен/)

    assert_equal 1, skipped.size
    assert_includes skipped.first, "issue ##{issue.id}"
    assert_includes skipped.first, User.find(3).name
    assert_includes skipped.first, '/connect'
  end

  it 'creates the chat anyway when a participant is unknown to the organization' do
    outsider = User.find(3)
    outsider.yandex_login = 'outsider@example.org'
    outsider.save!
    issue.update_columns(assigned_to_id: outsider.id)

    # only the creator resolves; the assignee is an outsider
    client = FakeClient.new(known: ['user2@example.org'])
    stub_client(client)

    result = platform.create_chat('Project 1', issue)

    assert result.success?, 'one unresolvable login must not cancel the whole chat'
    params = client.call_params(:create_chat)
    refute_includes (params[:admins] + params[:members]), 'outsider@example.org'
  end

  it 'reports into the chat who could not be added and why' do
    outsider = User.find(3)
    outsider.yandex_login = 'outsider@example.org'
    outsider.save!
    issue.update_columns(assigned_to_id: outsider.id)

    client = FakeClient.new(known: ['user2@example.org'])
    stub_client(client)

    platform.create_chat('Project 1', issue)

    report = client.calls.select { |c| c.first == :send_text }.map { |c| c.last[:text] }.last
    assert report, 'a report message must be sent into the new chat'
    assert_includes report, outsider.name
    assert_includes report, I18n.t('redmine_2chat.yandex.report.not_added')
    assert_includes report, I18n.t('redmine_2chat.yandex.problems.not_in_org', login: 'outsider@example.org')
  end

  it 'refuses when the creator is unknown to the organization' do
    stub_client(FakeClient.new(known: []))

    result = platform.create_chat('Project 1', issue)

    assert result.failure?
    assert_equal I18n.t('redmine_2chat.yandex.errors.creator_not_in_org', login: 'user2@example.org'),
                 result.failure
  end

  it 'stores the guid the lookup returned' do
    stub_client(FakeClient.new)

    platform.create_chat('Project 1', issue)

    assert_equal 'guid-user2@example.org', user.reload.yandex_account.guid
  end

  it 'records a created chat with its link and logins' do
    stub_client(FakeClient.new)

    logged = capture_log { platform.create_chat('Project 1', issue) }
    created = logged.grep(/чат создан/).first

    assert created
    assert_includes created, "issue ##{issue.id}"
    assert_includes created, 'chat 0/0/abc'
    assert_includes created, 'https://yandex.ru/chat/#/join/xyz'
    assert_includes created, 'user2@example.org'
  end

  it 'records the logins it tried when the API refuses the chat' do
    client = FakeClient.new
    client.define_singleton_method(:create_chat) do |**|
      raise RedmineBots::Yandex::Client::Error.new('Creating chat with user restricted by privacy settings', 403)
    end
    stub_client(client)

    logged = capture_log { platform.create_chat('Project 1', issue) }

    assert(logged.any? { |l| l.include?('чат не создан') && l.include?('user2@example.org') && l.include?('privacy settings') })
  end

  it 'records a closed chat and a failed message' do
    client = FakeClient.new(members: [{ 'login' => 'a@example.org', 'is_bot' => false }])
    stub_client(client)

    logged = capture_log { platform.close_chat('0/0/abc', 'Chat is closed') }

    assert(logged.any? { |l| l.include?('chat 0/0/abc') && l.include?('чат закрыт') })
  end

  it 'records why a message could not be delivered' do
    client = FakeClient.new
    client.define_singleton_method(:send_text) do |**|
      raise RedmineBots::Yandex::Client::Error.new('Bot is not a member of the chat', 403)
    end
    stub_client(client)

    logged = capture_log { platform.send_message('0/0/abc', 'hi') }

    assert(logged.any? { |l| l.include?('сообщение не отправлено') && l.include?('Bot is not a member') })
  end

  it 'fails with the API description when the request is rejected' do
    client = FakeClient.new
    client.define_singleton_method(:create_chat) do |**|
      raise RedmineBots::Yandex::Client::Error.new('Creating chat with user restricted by privacy settings', 403)
    end
    stub_client(client)

    result = platform.create_chat('Project 1', issue)

    assert result.failure?
    assert_includes result.failure, 'privacy settings'
  end

  it 'announces the closing and evicts every non-bot member' do
    client = FakeClient.new(members: [
      { 'login' => 'a@example.org', 'is_bot' => false },
      { 'login' => 'bot@example.org', 'is_bot' => true }
    ])
    stub_client(client)

    assert platform.close_chat('0/0/abc', 'Chat is closed').success?
    assert_equal 'Chat is closed', client.call_params(:send_text)[:text]
    assert_equal ['a@example.org'], client.call_params(:update_members)[:remove]
  end

  it 'translates HTML notifications into the Yandex markup' do
    client = FakeClient.new
    stub_client(client)

    platform.send_message('0/0/abc', '<b>Автор</b>', disable_web_page_preview: true, parse_mode: 'HTML')

    params = client.call_params(:send_text)
    assert_equal '**Автор**', params[:text]
    assert params[:disable_web_page_preview]
    refute params.key?(:parse_mode)
  end
end
