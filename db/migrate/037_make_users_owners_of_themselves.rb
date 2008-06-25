# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class MakeUsersOwnersOfThemselves < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      user.has_role('owner', user)
    end
  end

  def self.down
  end
end
