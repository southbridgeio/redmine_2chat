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
