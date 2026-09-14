class IssueChat < ApplicationRecord
  belongs_to :issue

  has_many :messages, class_name: 'ChatMessage'

  scope :active, -> { where(active: true) }
  scope :on_platform, ->(platform_name) { where(platform_name: platform_name.to_s) }

  validates :platform_name, presence: true

  def close(message = nil)
    platform.close_chat(im_id, message.presence || I18n.t('redmine_2chat.messages.closed_automatically'))
  end

  def platform
    Redmine2chat.platform(platform_name)
  end

  def platform_title
    platform&.title || platform_name.to_s.titleize
  end

  def inactive?
    !active
  end
end
