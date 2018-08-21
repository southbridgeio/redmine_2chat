class IssueChatsController < ApplicationController
  include Redmine2chat::Operations

  

  def create
    @issue = Issue.visible.find(params[:issue_id])
    @issue.with_lock do
      if @issue.active_chat.present? && @issue.active_chat.shared_url.present?
        redirect_to issue_path(@issue)
        return
      end

      CreateChat.(@issue)
    end

    @project = @issue.project

    @last_journal    = @issue.journals.visible.order('created_on').last
    new_journal_path = "#{issue_path(@issue)}/#change-#{@last_journal.id}"
    render js: "window.location = '#{new_journal_path}'"
  end

  def destroy
    @issue   = Issue.visible.find(params[:id])
    @project = @issue.project

    CloseChat.(@issue)

    @last_journal = @issue.journals.visible.order('created_on').last
    redirect_to "#{issue_path(@issue)}#change-#{@last_journal.id}"
  end
end
