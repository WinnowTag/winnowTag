#!/usr/bin/env ruby
# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#



require File.join(File.dirname(__FILE__), '../config/environment')
require 'ruby-prof'

Classifier.disabled = true
user = User.find(1)
feed = Feed.find(24)
  # Profile the code
result = RubyProf.profile do
  BulkTagging.create(:tagger => user, :filter => feed, :tags => {'bulk' => 1})
end

# Print a graph profile to text
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT, 5)
