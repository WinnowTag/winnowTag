module Selenium
  module Client

    # Client driver providing the complete API to drive a Selenium Remote Control
    class Driver
      include Selenium::Client::Base

      def self.instance(*args)
        return @instance if @instance

        @instance = new(*args)
        @instance.start_new_browser_session

        at_exit { @instance.close_current_browser_session }

        @instance
      end
    end
  
  end
end
