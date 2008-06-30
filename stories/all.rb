# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
dir = File.dirname(__FILE__)
Dir[File.expand_path("#{dir}/**/*.rb")].uniq.each do |file|
  require file
end