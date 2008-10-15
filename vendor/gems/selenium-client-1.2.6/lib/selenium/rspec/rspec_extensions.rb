require 'spec/example/example_group'

module Spec
  module Rails
    module Example
      class SeleniumExampleGroup < RailsExampleGroup
        CONFIG = YAML.load_file(File.join(RAILS_ROOT, "config", "selenium.yml")).symbolize_keys

        include ActionController::UrlWriter

        self.use_transactional_fixtures = false
        self.default_url_options = { :host => CONFIG[:test_host] }

	      attr_reader :selenium_driver
	      alias :page :selenium_driver

        before(:all) do
          @selenium_driver = Selenium::Client::Driver.instance "localhost", 4444, "*#{CONFIG[:browser]}", "http://#{CONFIG[:test_host]}", 10000
        end

        # before(:each) do
        #   selenium_driver.start_new_browser_session
        # end

        append_after(:each) do
          selenium_driver.delete_all_visible_cookies
          # selenium_driver.close_current_browser_session
        end

        Spec::Example::ExampleGroupFactory.register(:selenium, self)
      end
    end
  end
end
