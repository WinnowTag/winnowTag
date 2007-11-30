Selenium::configure do |config|
  config.browser 'firefox'
  # config.browser 'safari'
  # config.browser 'iexplore'

  # Uncomment for remote tests. You will need to run selenium-server.jar manually on the remote machine
  # config.selenium_server_host = '172.16.83.129' # IP Address of the machine in the remote machine
  # config.test_server_host = '192.168.50.116'    # IP Address of the machine running the winnow instance (most likely, this one)
  # config.start_selenium_server = false
end
