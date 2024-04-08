class AddOnDeleteCascadeToIssueReference < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :issue_chats, :issues
    add_foreign_key :issue_chats, :issue, column: :issue_id, on_delete: :cascade
  end
end
