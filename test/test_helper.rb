$VERBOSE = nil

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

require 'minitest/spec'
require 'minitest/mock'
require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

class Minitest::Spec
  around do |tests|
    DatabaseCleaner.cleaning(&tests)
  end
end

class ActiveSupport::TestCase
  # Add spec DSL
  extend Minitest::Spec::DSL
end
