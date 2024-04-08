class AddOnDeleteCascadeToIssueChatReference < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :chat_messages, :issue_chats
    add_foreign_key :chat_messages, :issue_chats, column: :issue_chat_id, on_delete: :cascade
  end
end
