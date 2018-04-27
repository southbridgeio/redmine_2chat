module Redmine2chat
  @@mutex = Mutex.new
  @@platforms = {}

  mattr_reader :platforms

  def self.register_platform(name, platform)
    @@mutex.synchronize { @@platforms[name] = platform }
  end

  def self.active_platform
    platforms[Setting.plugin_redmine_2chat['active_platform']]
  end
end
