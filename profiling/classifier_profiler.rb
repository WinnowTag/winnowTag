#!/usr/bin/env ruby
# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#


require File.join(File.dirname(__FILE__), '../config/environment')
require 'ruby-prof'

  # Profile the code
user = User.find(4)
classifier = user.classifier

result = RubyProf.profile do
  FeedItem.find(:all, :select => 'id', :order => 'feed_items.time DESC'). each do |fi|
    classifier.guess(fi)
  end
end

# Print a graph profile to text
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT, 5)
