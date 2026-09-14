module Redmine2chat::Platforms
  class Yandex < Base
    MESSAGE_OPTIONS = {
      disable_notification: :disable_notification,
      disable_web_page_preview: :disable_web_page_preview,
      reply_to_message_id: :reply_message_id
    }.freeze

    def available?
      RedmineBots::Yandex.enabled?
    end

    def create_chat(title, issue)
      unless available?
        Log.error('чат не создан: не задан OAuth-токен бота', issue: issue)
        return Failure(I18n.t('redmine_2chat.yandex.errors.not_configured'))
      end

      creator_problem = check_creator(issue)
      return creator_problem if creator_problem

      admins, members, problems = participants(issue)

      response = client.create_chat(name: title,
                                    description: chat_description(issue),
                                    admins: admins,
                                    members: members,
                                    public: true)

      chat_id = response['chat_id']
      chat_url = response['invite_link'].presence || RedmineBots::Yandex.web_chat_url(chat_id)

      Log.info("чат создан: #{chat_url}. #{logins_summary(admins, members)}", issue: issue, chat: chat_id)
      report_problems(chat_id, problems)

      Success(im_id: chat_id, chat_url: chat_url)
    rescue RedmineBots::Yandex::Error => e
      Log.error("чат не создан: #{reason(e)}. #{logins_summary(admins, members)}", issue: issue)
      Failure(error_message(e))
    end

    def close_chat(im_id, message)
      send_message(im_id, message)

      logins = client.chat_members(im_id).reject { |m| m['is_bot'] }.filter_map { |m| m['login'].presence }
      client.update_members(chat_id: im_id, remove: logins) if logins.any?

      Log.info("чат закрыт, удалено участников: #{logins.size}", chat: im_id)

      Success(true)
    rescue RedmineBots::Yandex::Error => e
      Log.error("чат не закрыт: #{reason(e)}", chat: im_id)
      Failure(error_message(e))
    end

    def send_message(im_id, message, params = {})
      unless available?
        Log.error('сообщение не отправлено: не задан OAuth-токен бота', chat: im_id)
        return
      end

      client.send_text(chat_id: im_id, text: TextFormatter.(message), **message_options(params))
    rescue RedmineBots::Yandex::Error => e
      Log.error("сообщение не отправлено: #{reason(e)}", chat: im_id)
      nil
    end

    def title
      I18n.t('redmine_2chat.yandex.title')
    end

    private

    def client
      RedmineBots::Yandex.client
    end

    def participants(issue)
      current_user = User.current

      wanted = [[current_user, :member], [issue.assigned_to, :member], [issue.author, :member]]
      wanted.unshift([current_user, :admin]) if current_user.allowed_to?(:manage_chat, issue.project)

      resolved = {}
      problems = {}

      wanted.each do |principal, role|
        next if principal.nil? || resolved.key?(principal) || problems.key?(principal)

        login, reason = resolve(principal)

        if reason
          problems[principal] = reason
          Log.warn("#{principal_name(principal)} не добавлен: #{problem_text(principal, reason)}", issue: issue)
          next
        end

        resolved[principal] = [login, role]
      end

      admins = resolved.values.select { |(_, role)| role == :admin }.map(&:first)
      members = resolved.values.select { |(_, role)| role == :member }.map(&:first)

      [admins, members, problems.to_a]
    end

    # @return [Array(String, nil)] on success, [nil, reason] otherwise
    def resolve(principal)
      login = RedmineBots::Yandex.login_for(principal)
      return [nil, skip_reason(principal)] if login.blank?

      guid = client.find_user(login)
      return [nil, :not_in_org] if guid.nil?

      remember_guid(principal, guid)

      [login, nil]
    end

    def remember_guid(principal, guid)
      account = principal.yandex_account
      return if account.nil? || account.guid.present? || guid.blank?

      account.update_columns(guid: guid)
    rescue StandardError => e
      Log.warn("не удалось сохранить guid для #{principal_name(principal)}: #{e.message}")
    end

    def check_creator(issue)
      _login, reason = resolve(User.current)
      return if reason.nil?

      Log.warn("чат не создан: у создателя #{principal_name(User.current)} — #{problem_text(User.current, reason)}",
               issue: issue)

      Failure(I18n.t("redmine_2chat.yandex.errors.creator_#{reason}",
                     login: RedmineBots::Yandex.login_for(User.current)))
    end

    def report_problems(chat_id, problems)
      return if problems.blank?

      lines = problems.map { |principal, reason| "• #{principal.name} — #{problem_text(principal, reason)}" }
      send_message(chat_id, [I18n.t('redmine_2chat.yandex.report.not_added'), *lines].join("\n"))
    end

    def problem_text(principal, reason)
      I18n.t("redmine_2chat.yandex.problems.#{reason}",
             login: (RedmineBots::Yandex.login_for(principal) if principal.is_a?(::User)))
    end

    def skip_reason(principal)
      return :not_a_user unless principal.is_a?(::User)
      return :inactive if principal.anonymous? || principal.locked?

      :not_linked
    end

    def principal_name(principal)
      "#{principal.name} (#{principal.class.name}##{principal.id})"
    end

    def logins_summary(admins, members)
      "Логины — админы: #{Array(admins).join(', ').presence || '—'}; " \
        "участники: #{Array(members).join(', ').presence || '—'}"
    end

    def chat_description(issue)
      "#{issue.subject} — #{issue_url(issue)}"
    end

    def issue_url(issue)
      "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue.id}"
    end

    def message_options(params)
      params.symbolize_keys.slice(*MESSAGE_OPTIONS.keys).transform_keys { |k| MESSAGE_OPTIONS[k] }
    end

    def error_message(error)
      I18n.t('redmine_2chat.yandex.errors.api', message: reason(error))
    end

    def reason(error)
      error.try(:description).presence || error.message
    end
  end
end
