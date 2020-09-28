class TelegramExecutingCommand < ActiveRecord::Base
  serialize :data

  belongs_to :account, class_name: 'TelegramAccount'

  before_create -> (model) { model.step_number = 1 }

  def self.retrieve(telegram_account_id)
    joins(:account).find_by(telegram_accounts: { telegram_id: telegram_account_id })
  end

  def resume!(action:)
    Redmine2chat::Telegram::LegacyCommands::BotCommand.new(action.message).execute
  end

  def continue(command)
    Redmine2chat::Telegram::LegacyCommands::BotCommand.new(command).send("execute_command_#{name}")
  end

  def cancel(command)
    destroy
    RedmineBots::Telegram.bot.async.send_message(chat_id: command.chat.id,
                                                 text: I18n.t('redmine_2chat.bot.command_canceled'),
                                                 reply_markup: ::Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true).to_json)
  end
end
