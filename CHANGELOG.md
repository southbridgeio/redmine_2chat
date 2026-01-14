# 0.5.0

* Add compatibility with Redmine 6.1
* Add compatibility with Ruby 3.3.x
* Add compatibility with 7.x
* Replace dependency gem 'sidekiq-rate-limiter' to gem 'sidekiq-throttled'
* The Sidekiq >= 6.5 is required now ( for Sidekiq < 6.5, please use sidekiq-throttled < 1.0)
* Bump plugin version to 0.5.0
* Fix tests coverage

# 0.4.5

* Add compatibility with Redmine 5.1
* Add kick locked users to supergroups

# 0.4.4

* Add functionality for processing photos from telegram

# 0.4.3

* Fix kick locked users

# 0.4.2

* Fix set admin permissions
* Refactor commands

# 0.4.1

* Adapt tdlib commands for new version

# 0.4.0

* Fix USER_NOT_PARTICIPANT error
* Fix redmine_checklists compatibility
* Refactor commands
* Toggle chat admins with bot
* Add chat creator to chat instantly and assign admin rights
* Fix db connection leak
* Release AR connections in KickLockedUsers command

# 0.3.2

* Handle supergroup upgrade error
* Fix toggle admin command
* Fix remove_keyboard error
* Don’t respond to locked members commands
* Handle "Administrators editing is disabled" errors

# 0.3.1

* Fix Rails 4 support

# 0.3.0

* Use new redmine_bots API
* Improve errors handling
* Add plugins deprecation warning

# 0.2.0

* Fix edit group admin command
* Prevent duplicate chats
* Fix IssueChatKickLockedUsersWorker error
* Truncate issue notes in bot messages
* Proxy telegram links through redmine
* Fix /issue command
* Fix /new command
* Adapt for Redmine 4
* Fix settings caching issues in sidekiq

# 0.1.0

* Initial release
