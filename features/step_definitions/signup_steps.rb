# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

When /^I use an unknown invitation code$/ do
  visit login_path(:invite => "UNKNOWN")
end

When /^I signup with the invitation$/ do
  visit login_path(:invite => @invite.code)
end