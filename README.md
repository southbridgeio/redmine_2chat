[![Build Status](https://travis-ci.org/southbridgeio/redmine_2chat.svg?branch=master)](https://travis-ci.org/southbridgeio/redmine_2chat)
[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_2chat)

# redmine_2chat

This plugin is used to create group chats in instant messengers.

The `redmine_2chat` can be used to create a group chat associated with an issue and record its logs to the Redmine archive. Associated group chats can be easily created via the `Create <Platform name> chat` link on the ticket page. You can copy the link and pass it to anyone you want to join this chat.

There're currently Telegram, Yandex Messenger and Slack supported to create chats in. Several platforms can be enabled at the same time — an issue then holds one chat per platform, each with its own link. You can also create your own platform adapter and register it.

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
become_chat_admin - Become admin in chat by invite link
```

### Yandex Messenger

The Yandex Messenger integration talks to the [Bot API](https://yandex.ru/dev/messenger/doc/ru/)
of Yandex 360 for Business. There is no userbot involved: the bot itself creates the chat and
becomes its administrator.

* Create a bot and issue its OAuth token at [admin.yandex.ru/bot-platform](https://admin.yandex.ru/bot-platform).
* Put the token into *Administration → Plugins → Redmine Bots → Yandex Messenger → OAuth bot token*.
* Enable `Yandex Messenger` in *Administration → Plugins → Redmine 2Chat → Active platforms*.
* Point the bot at this instance: `rake redmine_bots:yandex:set_webhook` (needs a public HTTPS host).
* Ask people to link their Yandex 360 account — see below.

Yandex 360 addresses people by login rather than by a numeric id, so every participant needs their
account linked. `redmine_bots` stores that binding in `YandexAccount` and offers two ways to create
it:

* **through the bot (preferred)** — a user sends `/connect` to it in a private chat and follows the
  one-time link back to Redmine. The login is asserted by Yandex, the Redmine user comes from the
  session, so neither side is self-declared; such a binding is marked verified.
* **by hand** — the *Yandex 360 login* field on *My account* (and on the admin user form). Handy for
  filling someone in ahead of time, but nothing checks it, so it stays unverified.

The field only shows up while a bot token is set. The Redmine e-mail is deliberately **not** used as
a fallback — a coincidental address match must never pull the wrong person into a chat — so a user
without a binding simply is not added to the chat.

Chats are created with `public: true`, so the stored link is a Yandex invite link. That link is the
only way somebody can join on their own: the bot itself can only add people it resolves in the
organization directory. Two things follow. The API offers no way to revoke the link, so closing a
chat evicts its members but cannot keep out someone who kept the link — and the link lives on in the
issue journal. And the link does **not** help outsiders: a person outside the organization is
refused by it just as the bot refuses to add them.

The issue creator (as an administrator, when they hold the `manage_chat` permission), the assignee
and the author are added as members — those of them with a linked Yandex 360 account. Every omission
is logged with its reason.

People from outside the organization need an extra step that has no API: an administrator has to add
them as a **guest** of the organization (*Общие контакты и гости → Гости* in the Yandex 360 admin
panel). A contact invited through Messenger's own "Пригласить в Мессенджер" is not enough — the bot
cannot see them at all. Note also that a guest's login is not their e-mail
(`ivan.petrov@yandex.ru` becomes `ivan-petrov`), so linking through the bot's `/connect` — which
takes the login straight from the webhook — is far more reliable than typing it by hand.

Two limitations come from the API itself:

* a bot can only add members of its own organization, and **one login it cannot resolve rejects the
  whole request**, so a participant from outside the organization fails the chat creation entirely;
* there is no archive/delete chat method — closing a chat posts the closing message and removes
  every non-bot member. The chat itself and its history remain, visible to the bot only.

Closing gives up rather than retrying forever: after `CloseChat::MAX_ATTEMPTS` failures the chat is
marked closed in Redmine alone and the issue journal records that the platform never confirmed it,
along with the last error.

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

* Enable Slack in the *Active platforms* setting on the plugin settings page.

## Custom platform adapters

You can create and register custom platform adapter by implementing simple contract:

```ruby
class ICQ < Redmine2chat::Platforms::Base # :)
  # @return [Success({ im_id:, chat_url: })] or [Failure(String)]
  def create_chat(title, issue)
    # needs to be implemented
  end

  # @return [Success] or [Failure(String)]
  def close_chat(im_id, message)
    # needs to be implemented
  end

  # `message` arrives as Telegram-flavoured HTML
  def send_message(im_id, message, params = {})
    # needs to be implemented
  end

  # whether the platform is configured well enough to be offered
  def available?
    true
  end
end

Redmine2chat.register_platform('icq', ICQ.new)

````

`Redmine2chat::Platforms::Base` derives `platform_name`, `title`, `icon_path` and
`inactive_icon_path` from the class name, so dropping `icq-icon.png` and `icq-inactive-icon.png`
into `assets/images` is enough; override the methods to change any of them.

Then, you can enable it in the *Active platforms* setting on the plugin settings page.

# Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
