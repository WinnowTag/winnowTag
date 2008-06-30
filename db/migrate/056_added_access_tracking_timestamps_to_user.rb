# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddedAccessTrackingTimestampsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :last_accessed_at, :datetime
    add_column :users, :last_session_ended_at, :datetime
    
    say "Setting everyones last accessed time to latter of the login or moderation time"
    User.transaction do
      User.find(:all).each do |user|
        time = [user.logged_in_at, user.last_tagging_on].compact.max
        user.last_accessed_at = time
        user.last_session_ended_at = time
        user.save
      end
    end
  end

  def self.down
    remove_column :users, :last_accessed_at
    remove_column :users, :last_session_ended_at
  end
end
