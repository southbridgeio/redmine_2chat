$VERBOSE = nil

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

require 'minitest/spec'
require 'minitest/mock'
require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ActiveSupport::TestCase
  # Add spec DSL
  extend Minitest::Spec::DSL
end
