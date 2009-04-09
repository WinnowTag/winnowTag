module Selenium
  class Configuration
    config_file = File.join(::Rails.root, "config", "selenium.yml")
    CONFIG = if File.exist?(config_file)
      YAML.load_file(config_file)
    else
      {'default' => {}}
    end
    
    def self.each(&block)
      (CONFIG.keys - ["default"]).each(&block)
    end
    
    def self.current_configuration
      ENV["SELENIUM_CONFIGURATION"] || :default
    end
    
    def self.selenium_host(configuration = current_configuration)
      CONFIG[configuration.to_s]["selenium_host"] || CONFIG["default"]["selenium_host"] || "localhost"
    end
    
    def self.selenium_port(configuration = current_configuration)
      CONFIG[configuration.to_s]["selenium_port"] || CONFIG["default"]["selenium_port"] || 4444
    end
    
    def self.browser(configuration = current_configuration)
      browser = CONFIG[configuration.to_s]["browser"] || CONFIG["default"]["browser"]
      "*#{browser}"
    end
    
    def self.test_host(configuration = current_configuration)
      CONFIG[configuration.to_s]["test_host"] || CONFIG["default"]["test_host"]
    end
    
    def self.test_url(configuration = current_configuration)
      "http://#{test_host(configuration)}"
    end
    
    def self.display(configuration = current_configuration)
      CONFIG[configuration.to_s]["display"] || CONFIG["default"]["display"]
    end
  end
end