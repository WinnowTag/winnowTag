# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/helper'

steps_for :login do
  When "I visit $path" do |path|
    get path
  end

  Then "I am redirected to $path with rjs" do |path|
    response.body.should =~ /window\.location\.href = "#{Regexp.escape(path)}";/
  end
  Then "I am redirected to $path" do |path|
    response.should redirect_to(path)
  end
end

with_steps_for :login do
  run_local_story "login", :type => RailsStory
end