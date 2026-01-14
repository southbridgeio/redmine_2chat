require File.expand_path('../../../test_helper', __FILE__)
require_relative '../../../app/workers/issue_chat_close_notification_worker.rb'
require_relative '../../../app/workers/issue_chat_auto_close_worker.rb'
require 'minitest/mock'
require 'minitest/autorun'

class IssueChatAutoCloseWorkerTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues

  before do
    @closed_status = IssueStatus.create(name: 'closed', is_closed: true)
    @opened_status = IssueStatus.create(name: 'opened', is_closed: false)

    Issue.find(1).update(status_id: @opened_status.id)
    Issue.find(2).update(status_id: @closed_status.id)

    @telegram_group = IssueChat.create(need_to_close_at: 1.day.from_now,
                                                                last_notification_at: 2.days.ago,
                                                                im_id: 123,
                                                                platform_name: 'telegram',
                                                                issue_id: 1)
    @another_telegram_group = IssueChat.create(need_to_close_at: 1.day.from_now,
                                                                        last_notification_at: 2.days.ago,
                                                                        im_id: 456,
                                                                        platform_name: 'telegram',
                                                                        issue_id: 2)
  end

  describe 'when close_issue_statuses setting present' do
    before do
      Setting['plugin_redmine_2chat'] = { 'close_issue_statuses' => [@opened_status.id.to_s] }
    end

    it 'closes groups only for issues with required statuses' do
      IssueChat.create(need_to_close_at: 1.day.ago,
                       last_notification_at: 2.days.ago,
                       im_id: 789,
                       platform_name: 'telegram',
                       issue_id: 1)

      mock_worker = Minitest::Mock.new.expect(:call, nil, [Issue])

      Redmine2chat::Operations::CloseChat.stub :call, mock_worker do
        IssueChatAutoCloseWorker.new.perform
      end

      mock_worker.verify
    end

    it 'notify only for issues with required statuses' do
      mock_worker = Minitest::Mock.new.expect(:call, nil, [Issue])

      Redmine2chat::Operations::CloseChat.stub :call, mock_worker do
        IssueChatCloseNotificationWorker.expects(:perform_async).with(1)
        IssueChatAutoCloseWorker.new.perform
      end
    end
  end

  describe 'when close_issue_statuses settings does not present' do
    before do
      Setting['plugin_redmine_2chat'] = { 'close_issue_statuses' => [] }
    end

    it 'close groups only for issues with required statuses' do
      IssueChat.create(need_to_close_at: 1.day.ago,
                       last_notification_at: 2.days.ago,
                       im_id: 890,
                       platform_name: 'telegram',
                       issue_id: 2)

      mock_worker = Minitest::Mock.new.expect(:call, nil, [Issue])

      Redmine2chat::Operations::CloseChat.stub :call, mock_worker do
        IssueChatAutoCloseWorker.new.perform
      end

      mock_worker.verify
    end

    it 'notify only for issues with required statuses' do
      mock_worker = Minitest::Mock.new.expect(:call, nil, [Issue])

      Redmine2chat::Operations::CloseChat.stub :call, mock_worker do
        IssueChatCloseNotificationWorker.expects(:perform_async).with(2)
        IssueChatAutoCloseWorker.new.perform
      end
    end
  end
end
