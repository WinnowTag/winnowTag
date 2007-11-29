module Selenium
  class Browser
    cattr_accessor :browsers
    self.browsers = []
    
    attr_reader :name, :default, :command, :selenium, :version
    
    # Remove Ruby definitions so they get passed to Selenium
    %w{select open eval type}.each { |m| undef_method m }
    
    # Define new browsers. The name must be unique.
    # 
    # == Options
    # * +command+ - The command to launch the browser. Defaults to "*#{name}".
    # * +default+ - Should this browser be tested by default? Defaults to true
    def initialize(name, options = {})
      @name = name
      
      options.reverse_merge!(:default => true, :command => "*#{name}")
      options.assert_valid_keys :default, :command
      
      raise DuplicateBrowser, name if self.class[name]
      
      @command, @default = options[:command], options[:default]
      
      browsers << self
    end
    
    # Connect to the Selenium server. Reuse existing connection if it exists
    def connect!(options = {})
      configuration = Configuration.default.merge(options)
      
      unless @selenium
        if configuration.start_test_server?
          @test_server = SubProcess.start "mongrel_rails start -c #{RAILS_ROOT} -e test -p #{configuration.test_server_port}"
          # sleep(5)
        end
        
        if configuration.start_selenium_server?
          server_path = File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. selenium-server.jar]))
          @selenium_server = SubProcess.start "java -jar #{server_path} -port #{configuration.selenium_server_port}"
          sleep(1)
        end
        
        @selenium = SeleneseInterpreter.new(configuration.selenium_server_host, configuration.selenium_server_port,
          command, "http://localhost:#{configuration.test_server_port}/")
        
        @selenium.start
        
        @version = eval("navigator.userAgent")
      end
      
      self
    rescue Errno::EBADF
      @selenium = nil
      raise ServerError, "Could not connect to the Selenium server on #{configuration.selenium_server_host}:#{configuration.selenium_server_port}"
    end
    
    # Close the open browser window and disconnect from the Selenium server
    def disconnect!
      configuration = Configuration.default
      
      @selenium.stop rescue nil
      @selenium = nil
      
      if configuration.start_test_server?
        @test_server.stop
        @test_server = nil
      end
      
      if configuration.start_selenium_server?
        @selenium_servet.stop
        @selenium_server = nil
      end
    end
    
    # Restart the browser
    def reconnect!
      disconnect!
      connect!
    end
    
    def method_missing(method_id, *arguments)
      command = selenium_command(method_id)
      execute(command, *arguments)
    end
    
    def execute(*args)
      connect!
      @selenium.send(*args)
    end
    
    def selenium_command(method)
      method = method.to_s
      methods = SeleneseInterpreter.instance_methods
      
      if methods.include?(method)
        method
        
      # assert_ methods return the corresponding is_ method
      elsif md = /^assert_/.match(method) and methods.include?("is_#{md.post_match}")
        "is_#{md.post_match}"
        
      # ? methods return the result of the corresponding is_ method
      elsif md = /\?$/.match(method) and methods.include?("is_#{md.pre_match}")
        "is_#{md.pre_match}"
      
      # get_ selenium methods can be used without the get_ prefix
      elsif methods.include?("get_#{method}")
        "get_#{method}"
        
      else
        raise InvalidCommand, method
      end
    end
    
    class << self
      def [](name)
        browsers.find { |b| b.name == name }
      end
      
      def selected
        env_browser_names = (ENV['BROWSERS'] || '').split(',')
        
        browsers.select do |browser|
          browser.default || env_browser_names.include?(browser.name)
        end
      end
      
      def disconnect_all!
        browsers.each do |browser|
          browser.disconnect! rescue nil
        end
      end
    end
  end
end
