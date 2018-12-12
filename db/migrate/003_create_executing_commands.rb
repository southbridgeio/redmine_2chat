class CreateExecutingCommands < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :telegram_executing_commands do |t|
      t.integer :account_id
      t.string :name
      t.integer :step_number
      t.text :data
    end
    add_index :telegram_executing_commands, :account_id
  end
end
