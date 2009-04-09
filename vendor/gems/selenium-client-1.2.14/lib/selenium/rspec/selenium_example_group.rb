# require 'spec/example/example_group'
require 'selenium/rspec/reporting/selenium_test_report_formatter'

module Spec
  module Rails
    module Example
      class SeleniumExampleGroup < RailsExampleGroup
        include ActionController::UrlWriter

        self.use_transactional_fixtures = false
        self.default_url_options = { :host => Selenium::Configuration.test_host }

	      attr_reader :selenium_driver
	      alias :page :selenium_driver

        before(:all) do
          @selenium_driver = Selenium::Client::Driver.instance(
            Selenium::Configuration.selenium_host, Selenium::Configuration.selenium_port,
            Selenium::Configuration.browser, Selenium::Configuration.test_url, 10
          )
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

        prepend_after(:each) do
          begin 
            Selenium::RSpec::SeleniumTestReportFormatter.capture_system_state(selenium_driver, self) if execution_error
            if selenium_driver.session_started?
              selenium_driver.set_context "Ending example '#{self.description}'"
            end
          rescue Exception => e
            STDERR.puts "Problem while capturing system state" + e
          end
        end

        append_before(:each) do
          begin 
            if selenium_driver && selenium_driver.session_started?
              selenium_driver.set_context "Starting example '#{self.description}'"
            end
          rescue Exception => e
            STDERR.puts "Problem while setting context on example start" + e
          end
        end

        attr_reader :execution_error

        def execute(options, instance_variables)
          options.reporter.example_started(self)
          set_instance_variables_from_hash(instance_variables)

          @execution_error = nil
          Timeout.timeout(options.timeout) do
            begin
              before_each_example
              eval_block
            rescue Exception => e
              @execution_error ||= e
            end
            begin
              after_each_example
            rescue Exception => e
              @execution_error ||= e
            end
          end

          options.reporter.example_finished(self, @execution_error)
          success = @execution_error.nil? || Spec::Example::ExamplePendingError === @execution_error
        end

        Spec::Example::ExampleGroupFactory.register(:selenium, self)
      end
    end
  end
end