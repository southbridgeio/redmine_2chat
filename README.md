[![Build Status](https://travis-ci.org/southbridgeio/redmine_2chat.svg?branch=master)](https://travis-ci.org/southbridgeio/redmine_2chat)
[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_2chat)

# redmine_2chat

This plugin is used to create group chats in instant messengers.

The `redmine_2chat` can be used to create a group chat associated with an issue and record its logs to the Redmine archive. Associated group chats can be easily created via the `Create <Platform name> chat` link on the ticket page. You can copy the link and pass it to anyone you want to join this chat.

There're currently Telegram and Slack supported to create chats in. You can also create your own platform adapter and register it.

Please help us make this plugin better telling us of any [issues](https://github.com/southbridgeio/redmine_2сhat/issues) you'll face using it. We are ready to answer all your questions regarding this plugin.


## Installation

### Requirements

* **Ruby 2.4+**
* Configured [redmine_bots](https://github.com/centosadmin/redmine_bots) (version 0.4.0 or higher)
* You need to use utf8mb4 encoding if you're using mysql database

Standard plugin installation:

```
cd {REDMINE_ROOT}
git clone https://github.com/southbridgeio/redmine_2chat.git plugins/redmine_2chat
bundle install RAILS_ENV=production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### Migration from redmine_chat_telegram

You can transparently migrate your old data (telegram chats and messages) to new DB structure if you used *redmine_chat_telegram* before with `bundle exec rake redmine_2chat:migrate_from_chat_telegram`.

## Usage

### Telegram
Make sure you have running sidekiq, turn on module in project, also connected Redmine and Telegram accounts (see /connect below).

Open the ticket. You'll see the new link `Create Telegram chat` on the right side of the ticket. Click on it and the Telegram group chat associated with this ticket will be created. The link will change to `Enter Telegram chat`. Click on it to join the chat in your Telegram client. You'll be able to copy and pass the link to anyone you want to invite to the Group Chat.

*Note: a new user in group will became group administrator, if his Telegram account connected to Redmine (see /connect below) and have proper permissions*

#### Available commands in dedicated bot chat

- `/connect account@redmine.com` - connect Telegram account to Redmine account
- `/new` - create new issue
- `/cancel` - cancel current command

#### Available commands in issue chat

- `/task`, `/link`, `/url` - get link to the issue
- `/log` - save message to the issue

##### Hints for bot commands

Use command `/setcommands` with [@BotFather](https://telegram.me/botfather). Send this list for setup hints:

```
start - Start work with bot.
connect - Connect account to Redmine.
new - Create new issue.
hot - Assigned to you issues updated today.
me - Assigned to you issues.
deadline - Assigned to you issues with expired deadline.
spent - Number of hours set today.
yspent - Number of hours set yesterday.
last - Last 5 issues with comments.
help - Help.
chat - Manage issues chats.
task - Get link to the issue.
link - Get link to the issue.
url - Get link to the issue.
log - Save message to the issue.
issue - Change issues.
```

### Slack

* Make sure you're done with configuring Slack in [redmine_bots](https://github.com/southbridgeio/redmine_bots).
* Set proper app scopes on your app Oauth and permissions page:

```
Add a bot user with the username @bot_name
bot 		

Access user’s public channels
channels:history 	

Access information about user’s public channels
channels:read 	

Modify your public channels
channels:write 		

Send messages as sbtest1
chat:write:bot 	

Send messages as user
chat:write:user	

Access content in user’s direct messages
im:history 	

Access information about user’s direct messages
im:read 	

Access information about your workspace
team:read
```

* Select Slack as active platform on plugin settings page.

## Custom platform adapters

You can create and register custom platform adapter by implementing simple contract:

```ruby
class ICQ # :)
  def create_chat(title)
    # needs to be implemented
  end

  def close_chat(im_id, message)
    # needs to be implemented
  end

  def send_message(im_id, message)
    # needs to be implemented
  end

  def icon_path
    # needs to be implemented
  end

  def inactive_icon_path
    # needs to be implemented
  end
end

Redmine2chat.register_platform('icq', ICQ.new)

````

Then, you can select it in on plugin settings page.

# Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
