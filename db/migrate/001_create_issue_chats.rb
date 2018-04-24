class CreateIssueChats < ActiveRecord::Migration
  def change
    create_table :issue_chats do |t|
      t.belongs_to :issue, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true
      t.string :im_id
      t.string :shared_url
      t.datetime :need_to_close_at
      t.datetime :last_notification_at
      t.string :platform_name
    end
    add_index :issue_chats, :im_id
    add_index :issue_chats, :platform_name
  end
end
