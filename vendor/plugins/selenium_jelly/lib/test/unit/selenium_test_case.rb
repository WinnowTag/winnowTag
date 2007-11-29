class Test::Unit::SeleniumTestCase < Test::Unit::TestCase
  include Selenium::Assertions
  
  # Remove Ruby's method definitions, Selenium uses these
  %w{select eval type}.each { |m| undef_method m }
  
  setup do
    unless @named_routes_configured
      ActionController::Routing::Routes.named_routes.install(self.class)
      @named_routes_configured = true
    end
  end
  
  def open(url)
    _execute_with_selenium('open', url_for(url))
  end
  
  # Catch-all for Selenium commands executed in tests
  def method_missing(*args)
    _execute_with_selenium(*args.map(&:to_s))
  end
  
  def run(result)
    @browsers ||= Selenium::Browser.selected
    
    if @browsers.empty?
      puts "You must define at least one browser in config/environment.rb"
      exit
    end
    
    @browsers.each do |@browser|
      super
    end
  end
  
 private
  def url_for(options)
    case options
      when String then options
      when Hash then
        @url_rewriter ||= ActionController::UrlRewriter.new(ActionController::TestRequest.new, nil)
        @url_rewriter.rewrite(options.merge(:only_path => true))
    end
  end
  
  def _execute_with_selenium(command, *arguments)
    selenium_command = @browser.selenium_command(command)
    
    if command.starts_with?('assert_')
      assert_block("Selenium assertion failure - #{command}: #{arguments.join(', ')}\n  #{@browser.version}") do
        @browser.execute(selenium_command, *arguments)
      end
    else
      @browser.execute(selenium_command, *arguments)
    end
  end
end
