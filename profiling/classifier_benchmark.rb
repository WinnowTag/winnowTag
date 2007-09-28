#!/usr/bin/env ruby
# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#


require File.join(File.dirname(__FILE__), '../config/environment')
require 'benchmark'

  # Profile the code
user = User.find(4)
classifier = user.classifier

bm = Benchmark.measure do
  FeedItem.find(:all, :select => 'id', :order => 'feed_items.time DESC'). each do |fi|
    classifier.classify(fi)
  end  
end
  
puts "Benchmark Results:\n"
puts bm
