require File.dirname(__FILE__) + '/lib/selenium'
require File.dirname(__FILE__) + '/lib/selenium/base'

if RAILS_ENV == 'test'
  at_exit do
    Selenium::Browser.disconnect_all! if Selenium::Configuration.default.close_browser_on_exit?
    Selenium::Server.disconnect!
  end
  
  require 'testcase_setup_and_teardown_with_blocks'
  require 'objectspace'
end
