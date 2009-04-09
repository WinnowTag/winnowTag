require 'test/unit'
require File.dirname(__FILE__) + "/../test_utils/behaviors/lib/behaviors.rb"

class Test::Unit::TestCase
  extend Behaviors
end

def require_relative *files
  files.each do |file|
    require File.dirname(__FILE__) + "/" + file
  end
end