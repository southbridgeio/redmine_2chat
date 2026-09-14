class IssueChatsController < ApplicationController
  include Redmine2chat::Operations

  skip_before_action :check_if_login_required, only: :tg_join

  def create
    @issue = Issue.visible.find(params[:issue_id])
    platform_name = params[:platform].presence || Redmine2chat.active_platform_names.first

    existing_chat = @issue.active_chat_for(platform_name)

    if existing_chat.present? && existing_chat.shared_url.present?
      redirect_to issue_path(@issue)
      return
    end

    CreateChat.(@issue, platform_name).fmap do
      @project = @issue.project

      @last_journal = @issue.journals.visible.order('created_on').last
      new_journal_path = "#{issue_path(@issue)}/#change-#{@last_journal.id}"
      render js: "window.location = '#{new_journal_path}'"
    end.or do |error|
      flash[:error] = error
      render js: "window.location = '#{issue_path(@issue)}'"
    end
  end

  def destroy
    @issue = Issue.visible.find(params[:id])
    @project = @issue.project

    CloseChat.(@issue, params[:platform]).fmap do
      @last_journal = @issue.journals.visible.order('created_on').last
      redirect_to "#{issue_path(@issue)}#change-#{@last_journal.id}"
    end.or do |error|
      flash[:error] = error
      redirect_to issue_path(@issue)
    end
  end

  def tg_join
    redirect_to "tg://join?invite=#{params[:invite_id]}"
  end
end
