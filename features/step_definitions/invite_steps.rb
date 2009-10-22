# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

Given /^an invitation that has already been used$/ do
  @invite = Generate.invite! :user_id => 1
  @invite.activate!
end
