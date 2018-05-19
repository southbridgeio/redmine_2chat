require File.expand_path('../../../../test_helper', __FILE__)

class Redmine2chat::Telegram::Commands::NewIssueCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :email_addresses, :roles, :issue_statuses

  let(:issue) { Issue.find(1) }
  let(:user) { User.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today.to_time.to_i,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  let(:command) { Telegram::Bot::Types::Message.new(command_params) }

  describe '#execute' do
    it 'sends that account not found if there is no accout' do
      text = I18n.t('redmine_2chat.bot.account_not_found')
      Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
    end

    describe 'when account is present' do
      before do
        @account = ::TelegramAccount.create(telegram_id: 998_899, user_id: user.id)
        Redmine2chat.active_platform.stubs(:create_chat).returns(im_id: 1, chat_url: 'http://telegram.me/chat')
      end

      describe 'step 1' do
        it 'sends projects available for the user' do
          project_list = [['eCookbook', 'Private child of eCookbook'],
                          ['Child of private child', 'eCookbook Subproject 1'],
                          ['eCookbook Subproject 2', 'OnlineStore']]

          Telegram::Bot::Types::ReplyKeyboardMarkup.expects(:new)
            .with(keyboard: project_list, one_time_keyboard: true, resize_keyboard: true)
            .returns(nil)

          text = I18n.t('redmine_2chat.bot.new_issue.choice_project_without_page')
          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(text, reply_markup: nil)

          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
        end
      end

      describe 'step 2' do
        before do
          TelegramExecutingCommand.create(account: @account,
                                                       name: 'new',
                                                       data: {current_page: 1})
            .update(step_number: 2)
        end

        it 'sends list of project members if they are exist' do
          member = Member.create(project_id: 1, user_id: 1)
          member.roles << Role.first
          member.save

          command = Telegram::Bot::Types::Message
                      .new(command_params.merge(text: Project.first.name))

          users_list = [[I18n.t('redmine_2chat.bot.new_issue.without_user'), 'Redmine Admin']]
          Telegram::Bot::Types::ReplyKeyboardMarkup.expects(:new)
            .with(keyboard: users_list, one_time_keyboard: true, resize_keyboard: true)
            .returns(nil)

          text = I18n.t('redmine_2chat.bot.new_issue.choice_user')
          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(text, reply_markup: nil)

          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
        end

        it 'sends message that users are not found it there is no project members' do
          text = I18n.t('redmine_2chat.bot.new_issue.user_not_found')
          Telegram::Bot::Types::ReplyKeyboardRemove.expects(:new).returns(nil)
          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(text, reply_markup: nil)

          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
        end
      end

      describe 'step 3' do
        before do
          TelegramExecutingCommand.create(account: @account, name: 'new', data: {})
            .update(step_number: 3)
        end

        it 'asks to send issue subject' do
          command = Telegram::Bot::Types::Message
                      .new(command_params.merge(text: 'Redmine Admin'))

          text = I18n.t('redmine_2chat.bot.new_issue.input_subject')
          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(text)

          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
        end
      end

      describe 'step 4' do
        before do
          TelegramExecutingCommand.create(account: @account, name: 'new', data: {})
            .update(step_number: 4)
        end

        it 'asks to send issue text' do
          command = Telegram::Bot::Types::Message
                      .new(command_params.merge(text: 'issue subject'))

          text = I18n.t('redmine_2chat.bot.new_issue.input_text')
          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(text)

          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
        end
      end

      describe 'step 5' do
        before do
          IssuePriority.create(is_default: true, name: 'normal')
          Project.find(1).trackers << Tracker.first
          TelegramExecutingCommand.create(
            account: @account,
            name: 'new',
            data: { project_name: 'eCookbook',
                    user: { firstname: 'Redmine',
                            lastname: 'Admin' },
                    subject: 'Issue created from telegram' }).update(step_number: 5)
        end

        let(:command) { Telegram::Bot::Types::Message.new(command_params.merge(text: 'issue text')) }
        let(:url_base) { "#{Setting.protocol}://#{Setting.host_name}" }

        it 'sends message with link to the created issue and question to create chat' do
          new_issue_id = Issue.last.id + 1

          users_list = [%w(Yes No)]
          Telegram::Bot::Types::ReplyKeyboardMarkup.expects(:new)
            .with(keyboard: users_list, one_time_keyboard: true, resize_keyboard: true)
            .returns(nil)

          text = <<HTML
#{I18n.t('redmine_2chat.bot.new_issue.success')} <a href="#{url_base}/issues/#{new_issue_id}">##{new_issue_id}</a>
#{I18n.t('redmine_2chat.bot.new_issue.create_chat_question')}
HTML
          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(text.chomp, reply_markup: nil)

          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
        end
      end

      describe 'step 6' do
        before do
          IssuePriority.create(is_default: true, name: 'normal')
          Project.find(1).trackers << Tracker.first
          TelegramExecutingCommand
            .create(account: @account, data: { issue_id: 1 }, name: 'new').update(step_number: 6)
        end

        let(:shared_url) { 'http://telegram.me/chat' }

        let(:chat) do
          issue.create_telegram_group(shared_url: shared_url, telegram_id: 123_456)
        end

        it 'creates chat for issue is user send "yes"' do
          Telegram::Bot::Types::ReplyKeyboardRemove.expects(:new).returns(nil)

          command = Telegram::Bot::Types::Message.new(command_params.merge(text: 'Yes'))

          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(
              I18n.t('redmine_2chat.bot.creating_chat'),
              reply_markup: nil
            )
          Redmine2chat::Telegram::Commands::BaseBotCommand.any_instance
            .expects(:send_message)
            .with(
              I18n.t(
                'redmine_2chat.journal.chat_was_created',
                chat_url: shared_url
              )
            )

          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
        end

        it 'hides keyborad and do nothing when user send "no"' do
          command = Telegram::Bot::Types::Message.new(command_params.merge(text: 'No'))
          Redmine2chat::Telegram::Commands::NewIssueCommand.new(command).execute
          # TODO: what we need to test here?
        end
      end
    end
  end
end
