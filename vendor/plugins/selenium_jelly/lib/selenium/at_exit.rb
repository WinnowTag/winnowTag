if RAILS_ENV == 'test'
  at_exit { Selenium::Browser.disconnect_all! if Selenium::Configuration.default.close_browser_on_exit? }
  at_exit { Selenium::Server.disconnect! }
end
