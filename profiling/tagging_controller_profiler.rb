# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
RAILS_ENV = 'development'
require File.join(File.dirname(__FILE__), '../config/environment')
require 'ruby-prof'
require 'console_app'

app.class
app.post '/account/login', :login => 'jed', :password => 'lau1rel'
result = RubyProf.profile do
  app.get '/taggings/update', :tagging => {:taggable_id => 1, :taggable_type => 'FeedItem'}
end

# Print a graph profile to text
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT, 5)
