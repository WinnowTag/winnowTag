# inject hpricot test helper into test::unit for test environment
if RAILS_ENV == 'test'
  require 'test/unit'
  Test::Unit::TestCase.send(:include, HpricotTestHelper)
end