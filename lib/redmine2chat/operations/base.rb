module Redmine2chat::Operations
  class Base
    include Dry::Monads::Result::Mixin

    def self.call(*args, **kwargs)
      new(*args, **kwargs).call
    end

    def call(*)
      raise NotImplementedError
    end

    private

    def add_journal(issue, text, user = User.current)
      journaled = Issue.find(issue.id)
      journaled.init_journal(user, text)
      journaled.save!
    end
  end
end
