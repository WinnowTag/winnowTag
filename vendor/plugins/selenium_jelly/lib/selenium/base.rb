require 'selenium'

module Selenium
  class InvalidCommand < Exception
  end
  
  class ServerError < Exception
  end
  
  class DuplicateBrowser < Exception
  end
  
  def self.configure(&block)
    Configuration.default.configure(&block)
  end
  
  # Configure the location of the Selenium and testing servers
  # 
  # == Server configuration
  # * +selenium_server_host+ - The location of the server running Selenium-RC. Default: localhost
  # * +selenium_server_port+ - The port to connect to on selenium_server_host. Default: 4444
  # * +test_server_port+ - The port to connect to on localhost for the test server. Default: 3001
  # 
  # == Other
  # * +close_browser_on_exit+ - Should the automatically launched browsers be closed when the tests have finished. Either true or false. Default: true
  # 
  # == Example
  # 
  # In config/environment.rb:
  # 
  #   Selenium::configure do |config|
  #     config.selenium_server_host = '192.168.1.10'
  #     config.close_browser_on_exit = false
  #     
  #     config.browser 'firefox'
  #     config.browser 'iexplore', :default => false
  #   end
  class Configuration
    cattr_accessor :default
    attr_accessor :options
    
    def initialize(options = {})
      @options = options
    end
    
    def method_missing(method_id, *arguments)
      method_name = method_id.to_s
      
      if md = /=$/.match(method_name)
        options[md.pre_match] = arguments.first
      else
        options[method_name.gsub(/\?$/, '')]
      end
    end
      
    def configure
      yield self
    end
    
    def merge(options)
      c = dup
      c.options.update(options)
      c
    end
    
    def browser(*args)
      Browser.new(*args)
    end
    
    @@default = new(
      'selenium_server_host'  => 'localhost',
      'selenium_server_port'  => 4444,
      'browser_command'       => '*firefox',
      'test_server_port'      => 3001,
      'close_browser_on_exit' => true
    )
  end
end
