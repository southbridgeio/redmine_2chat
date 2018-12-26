class TelegramExecutingCommand < ActiveRecord::Base
  

  serialize :data

  belongs_to :account, class_name: 'TelegramAccount'

  before_create -> (model) { model.step_number = 1 }

  def continue(command)
    Redmine2chat::Telegram::Commands::BotCommand.new(command).send("execute_command_#{name}")
  end

  def cancel(command)
    destroy
    RedmineBots::Telegram::Bot::MessageSender.call(
        bot_token: RedmineBots::Telegram.bot_token,
        chat_id: command.chat.id,
        message: I18n.t('redmine_2chat.bot.command_canceled'),
        reply_markup: ::Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true).to_json)
  end
end
