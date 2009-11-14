# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveLastSessionEndedAtFromUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :last_session_ended_at
  end

  def self.down
    add_column :users, :last_session_ended_at, :datetime
  end
end
