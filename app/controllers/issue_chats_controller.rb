class IssueChatsController < ApplicationController
  include Redmine2chat::Operations

  skip_before_action :check_if_login_required, only: :tg_join

  def create
    @issue = Issue.visible.find(params[:issue_id])
    @issue.with_lock do
      if @issue.active_chat.present? && @issue.active_chat.shared_url.present?
        redirect_to issue_path(@issue)
        return
      end

      CreateChat.(@issue).then do
        @project = @issue.project

        @last_journal    = @issue.journals.visible.order('created_on').last
        new_journal_path = "#{issue_path(@issue)}/#change-#{@last_journal.id}"
        render js: "window.location = '#{new_journal_path}'"
      end.rescue do |error|
        flash[:error] = error.message
        render js: "window.location = '#{issue_path(@issue)}'"
      end.wait
    end
  end

  def destroy
    @issue   = Issue.visible.find(params[:id])
    @project = @issue.project

    CloseChat.(@issue).then do
      @last_journal = @issue.journals.visible.order('created_on').last
      redirect_to "#{issue_path(@issue)}#change-#{@last_journal.id}"
    end.rescue do |error|
      flash[:error] = error.message
      redirect_to issue_path(@issue)
    end.wait
  end

  def tg_join
    redirect_to "tg://join?invite=#{params[:invite_id]}"
  end
end
