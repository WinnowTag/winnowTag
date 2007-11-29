require 'test/unit/collector/objectspace'

module Test
  module Unit
    module Collector
      class ObjectSpace
        def collect(name=NAME)
          suite = TestSuite.new(name)
          sub_suites = []
          @source.each_object(Class) do |klass|
            # Ignore SeleniumTestCase even though it is a subclass of TestCase
            if(Test::Unit::TestCase > klass && klass != Test::Unit::SeleniumTestCase)
              add_suite(sub_suites, klass.suite)
            end
          end
          sort(sub_suites).each{|s| suite << s}
          suite
        end
      end
    end
  end
end
