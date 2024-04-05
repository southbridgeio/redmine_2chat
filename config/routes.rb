resources :issue_chats, only: [:create, :destroy]
get 'issues/:id/chat_messages' => 'chat_messages#index', as: 'issue_chat_messages'
post 'issues/:id/chat_messages/publish' => 'chat_messages#publish', as: 'publish_issue_chat_messages'

get 'tg/:invite_id' => 'issue_chats#tg_join'
get 'tg_message/:chat_id/:message_id' => 'chat_messages#tg_message'
