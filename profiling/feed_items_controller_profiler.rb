# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Re-raise errors caught by the controller.
RAILS_ENV = 'production'
require File.join(File.dirname(__FILE__), '../config/environment')
require 'ruby-prof'
require 'action_controller/integration'

app = ActionController::Integration::Session.new
app.post '/account/login', :login => 'seangeo', :password => 'flurgen'
app.get '/feed_items.js'

result = RubyProf.profile do
  app.get '/feed_items.js'
end

if app.status != 200
  puts app.status
  exit(1)
end

# Print a graph profile to text
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT)


