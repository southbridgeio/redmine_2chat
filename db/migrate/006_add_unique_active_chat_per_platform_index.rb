class AddUniqueActiveChatPerPlatformIndex < ActiveRecord::Migration[7.2]
  INDEX_NAME = 'index_issue_chats_on_issue_and_platform_active'.freeze

  def up
    deduplicate_active_chats

    add_index :issue_chats, %i[issue_id platform_name],
              unique: true, where: 'active', name: INDEX_NAME
  end

  def down
    remove_index :issue_chats, name: INDEX_NAME
  end

  private

  def deduplicate_active_chats
    execute <<~SQL
      UPDATE issue_chats SET active = false
      WHERE active
        AND id NOT IN (
          SELECT MAX(id) FROM issue_chats
          WHERE active
          GROUP BY issue_id, platform_name
        )
    SQL
  end
end
