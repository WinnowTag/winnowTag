# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class MakeUsersOwnersOfThemselves < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      user.has_role('owner', user)
    end
  end

  def self.down
  end
end
