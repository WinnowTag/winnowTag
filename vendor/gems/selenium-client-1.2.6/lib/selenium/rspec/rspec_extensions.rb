require 'spec/example/example_group'

module Spec
  module Rails
    module Example
      class SeleniumExampleGroup < RailsExampleGroup
        config_file = File.join(::Rails.root, "config", "selenium.yml")
        CONFIG = if File.exist?(config_file)
          YAML.load_file(config_file).symbolize_keys
        else
          {}
        end

        include ActionController::UrlWriter

        self.use_transactional_fixtures = false
        self.default_url_options = { :host => CONFIG[:test_host] }

	      attr_reader :selenium_driver
	      alias :page :selenium_driver

        before(:all) do
          @selenium_driver = Selenium::Client::Driver.instance "localhost", 4444, "*#{CONFIG[:browser]}", "http://#{CONFIG[:test_host]}", 10000
        end

        # prepend_before(:each) do
        #   page.start_new_browser_session
        # end

        append_after(:each) do
          # Some deletes fail because of foreign key constraints. Catch any failures and try then again. Eventually it will work out.
          classes = ActiveRecord::Base.send(:subclasses).select(&:table_exists?)
          while classes.size > 0
            begin
              classes.first.delete_all
              classes.shift
            rescue
              classes << classes.shift
            end
          end

          # page.close_current_browser_session

          page.delete_all_visible_cookies
          
          page.get_all_window_names[1..-1].each do |window|
            page.select_window window
            page.close
          end
          
          page.select_window nil
        end

        Spec::Example::ExampleGroupFactory.register(:selenium, self)
      end
    end
  end
end
