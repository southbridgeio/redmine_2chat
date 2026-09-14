class AddCloseAttemptsToIssueChats < ActiveRecord::Migration[7.2]
  def change
    add_column :issue_chats, :close_attempts, :integer, default: 0, null: false
  end
end
