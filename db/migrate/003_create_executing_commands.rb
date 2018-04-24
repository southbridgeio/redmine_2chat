class CreateExecutingCommands < ActiveRecord::Migration
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
