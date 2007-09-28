#!/usr/bin/env ruby
#
#  Created by Sean Geoghegan on 2006-09-30.
#  Copyright (c) 2006. All rights reserved.

# Re-raise errors caught by the controller.
RAILS_ENV = 'production'
require File.join(File.dirname(__FILE__), '../config/environment')
require 'ruby-prof'
require 'action_controller/integration'

app = ActionController::Integration::Session.new
app.post '/account/login', :login => 'seangeo', :password => 'password'
app.get '/feed_items/index/0.js?tag_filter=all'

result = RubyProf.profile do
  app.get '/feed_items/index/0.js?tag_filter=all'
end

exit(1, "Error") if app.status != 200

# Print a graph profile to text
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT, 10)


