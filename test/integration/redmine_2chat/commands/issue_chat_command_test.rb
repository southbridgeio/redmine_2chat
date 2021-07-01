require File.expand_path('../../../../test_helper', __FILE__)
require File.expand_path('../../../../../app/workers/issue_chat_message_sender_worker', __FILE__)

class Redmine2chat::Telegram::LegacyCommands::IssueChatCommandTest < ActiveSupport::TestCase
  include Dry::Monads::Result::Mixin

  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :journals, :email_addresses, :enabled_modules

  let(:user) { User.find(1) }
  let(:issue) { Issue.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today.to_time.to_i,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  let(:chat) do
    issue.chats.create(shared_url: 'http://telegram.me/chat', im_id: 123_456, platform_name: 'telegram')
  end

  before do
    TelegramAccount.create(user_id: user.id, telegram_id: 998_899)
    Redmine2chat.active_platform.stubs(:create_chat).returns(Success(im_id: 1, chat_url: 'http://telegram.me/chat'))
    Redmine2chat::Operations::CloseChat.stubs(:call)
  end

  describe '/chat' do
    it 'sends help' do
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with(I18n.t('redmine_2chat.bot.chat.help'))

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end
  end

  describe '/chat info' do
    it 'sends link to chat if user has required rights' do
      User.any_instance.stubs(:allowed_to?).returns(true)
      chat
      text = 'http://telegram.me/chat'
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with(text)

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end

    it "sends 'access denied' message if user hasn't required rights" do
      text = 'Access denied.'
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
          .expects(:send_message)
          .with(text)
      User.any_instance.stubs(:allowed_to?).returns(false)
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end

    it "sends 'chat not found' message if chat not found" do
      text = 'Chat not found.'
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with(text)
      User.any_instance.stubs(:allowed_to?).returns(true)
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end

    it "sends 'issue not found' message if issue not found" do
      issue.destroy
      text = 'Issue not found.'
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with(text)
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end
  end

  describe '/chat create' do
    it 'creates chat if user has required rights and module is enabled' do
      EnabledModule.create(name: 'chat_telegram', project_id: 1)
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with('Creating chat. Please wait.')
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with('Chat was created. Join it here: http://telegram.me/chat')

      User.any_instance.stubs(:allowed_to?).returns(true)

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat create 1'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end

    it "doesn't create chat is plugins module is disabled" do
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with('Telegam chat plugin for current project is disabled.')
      User.any_instance.stubs(:allowed_to?).returns(true)

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat create 1'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end
  end

  describe '/chat close' do
    it 'closes chat if it exists and user has required rights' do
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.any_instance
        .expects(:send_message)
        .with('Chat was successfully destroyed.')
      User.any_instance.stubs(:allowed_to?).returns(true)

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat close 1'))
      Redmine2chat::Telegram::LegacyCommands::IssueChatCommand.new(command).execute
    end
  end
end
