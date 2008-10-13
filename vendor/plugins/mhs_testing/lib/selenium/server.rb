module Selenium
  class Server
    class << self
      def selenium_server
        @selenium_server ||= SubProcess.find(selenium_server_command)
      end
      
      def selenium_server_command
        server_path = File.expand_path(File.join(File.dirname(__FILE__), "selenium-server.jar"))
        "java -jar #{server_path} -port #{configuration.selenium_server_port}"
      end
      
      def configuration
        Selenium.configuration
      end
      
      def connect!(options = {})
        unless selenium_server
          environment = {}
          environment['DISPLAY'] = configuration.selenium_server_display if configuration.selenium_server_display
          @selenium_server = SubProcess.start(selenium_server_command, environment)
        end
      end
    
      def disconnect!
        if configuration.stop_selenium_server? && selenium_server
          @selenium_server.stop
          @selenium_server = nil
        end
      end
    end
  end
end
