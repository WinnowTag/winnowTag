Selenium::configure do |config|
  config.browser 'firefox'
  # config.browser 'safari'
  # config.browser 'iexplore'

  # Uncomment for remote tests. You will need to run selenium-server.jar manually on the remote machine
  # config.selenium_server_host = '172.16.83.129' # IP Address of the machine in the remote machine
  config.stop_selenium_server = false
  config.selenium_server_display = ':0'

  config.test_server_host = 'test.winnow.local'
  config.test_server_port = 80
  # config.close_browser_at_exit = false
end
