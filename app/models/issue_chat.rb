class IssueChat < ActiveRecord::Base
  belongs_to :issue

  has_many :messages, class_name: 'ChatMessage'

  scope :active, -> { where(active: true) }

  def close
    platform.close_chat(self)
  end

  def platform
    Redmine2chat.platforms[platform_name]
  end
end
