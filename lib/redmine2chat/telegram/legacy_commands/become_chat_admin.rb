# frozen_string_literal: true

module Redmine2chat::Telegram
  module LegacyCommands
    class BecomeChatAdmin < BaseBotCommand
      def execute
        return if account.blank?

        if command_arguments.blank?
          return send_message(I18n.t("redmine_2chat.bot.private.become_chat_admin.command_arguments_blank"),
                              parse_mode: "HTML"
          )
        end

        chat = IssueChat.find_by(shared_url: command_arguments.strip)

        process_action(chat: chat)
      end

      private

      def process_action(chat:)
        if chat.blank?
          send_message(I18n.t("redmine_2chat.bot.private.become_chat_admin.chat_not_found"))
        elsif chat.inactive?
          send_message(I18n.t("redmine_2chat.bot.private.become_chat_admin.chat_inactive"))
        elsif user_can_not_manage_chat?(project: chat.issue.project)
          send_message(I18n.t("redmine_2chat.bot.private.become_chat_admin.user_has_not_permissions"))
        else
          begin
            edit_member_permissions_in_chat(chat_id: chat.im_id)
            send_message(I18n.t("redmine_2chat.bot.private.become_chat_admin.success"))
          rescue => e
            send_error_message(error_message: e.message)
          end
        end
      end

      def edit_member_permissions_in_chat(chat_id:)
        RedmineBots::Telegram.bot.promote_chat_member(chat_id: chat_id,
                                                      user_id: account.telegram_id,
                                                      can_manage_chat: true,
                                                      can_change_info: true,
                                                      can_delete_messages: true,
                                                      can_invite_users: true,
                                                      can_restrict_members: true,
                                                      can_pin_messages: true,
                                                      can_manage_topics: true,
                                                      can_promote_members: true,
                                                      can_manage_video_chats: true,
                                                      is_anonymous: false
        )
      end

      def send_error_message(error_message:)
        error_description = error_message.match(/description: "(.*?)"/)

        if error_description
          send_message("#{I18n.t("redmine_2chat.bot.private.become_chat_admin.fail")}: #{error_description[1]}")
        else
          send_message(error_message)
        end
      end

      def user_can_not_manage_chat?(project:)
        !account.user.allowed_to?(:manage_chat, project)
      end
    end
  end
end
