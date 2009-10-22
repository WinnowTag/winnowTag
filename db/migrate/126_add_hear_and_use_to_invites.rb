# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddHearAndUseToInvites < ActiveRecord::Migration
  def self.up
    add_column :invites, :hear, :text
    add_column :invites, :use, :text
  end

  def self.down
    remove_column :invites, :use
    remove_column :invites, :hear
  end
end
