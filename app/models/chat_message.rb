class ChatMessage < ActiveRecord::Base
  include Redmine::I18n

  unloadable

  default_scope { joins(issue: :project).order(sent_at: :desc) }
  scope :reverse_scope, -> { unscope(:order).order('sent_at ASC') }

  belongs_to :issue

  acts_as_searchable columns: %w[message first_name last_name username],
                     project_key: "#{Project.table_name}.id",
                     scope: ->(options) do
                       relation = where(issue_id: options.fetch(:issue_id)).order(sent_at: :desc)
                       relation = relation.where("cast(#{table_name}.sent_at as date) <= ?", DateTime.parse(options[:to_date])) if options[:to_date].present?
                       relation
                     end

  COLORS_NUMBER = 8

  def self.as_text
    all.map(&:as_text).join("\n\n")
  end

  def as_text(with_time: true)
    if with_time
      format_time(sent_at) + ' ' + author_name + ': ' + message
    else
      author_name + ': ' + message
    end
  end

  def author_name
    full_name = [first_name, last_name].join(' ').strip
    full_name.present? ? full_name : username
  end

  def author_initials
    if first_name && last_name
      [first_name.first, last_name.first].join
    elsif username
      username[0..1]
    elsif first_name
      first_name[0..1]
    elsif last_name
      last_name[0..1]
    else
      '--'
    end
  end

  def user_id
    im_id
  end
end
