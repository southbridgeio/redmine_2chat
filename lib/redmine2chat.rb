module Redmine2chat
  @@mutex = Mutex.new
  @@platforms = {}

  mattr_reader :platforms

  def self.register_platform(name, platform)
    @@mutex.synchronize { @@platforms[name.to_s] = platform }
  end

  def self.platform(name)
    platforms[name.to_s]
  end

  def self.settings
    Setting.plugin_redmine_2chat
  end

  def self.active_platform_names
    names = settings['active_platforms'].presence || settings['active_platform']

    Array(names).map(&:to_s).reject(&:blank?).uniq & platforms.keys
  end

  def self.active_platforms
    platforms.values_at(*active_platform_names)
  end

  def self.available_platforms
    active_platforms.select(&:available?)
  end

  def self.active_platform?(name)
    active_platform_names.include?(name.to_s)
  end

  def self.active_platform
    active_platforms.first
  end
end
