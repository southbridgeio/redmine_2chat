class CreateChatMessages < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :chat_messages do |t|
      t.string :im_id
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :issue_chat, index: true, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :username
      t.datetime :sent_at
      t.text :message
      t.timestamp :created_on
      t.string :system_data
      t.boolean :is_system, default: false, null: false
    end
    add_index :chat_messages, :im_id
  end
end