class IssueChat < ActiveRecord::Base
  def close
    platform.close_chat(self)
  end

  def platform
    Redmine2chat.platforms[platform_name]
  end
end
