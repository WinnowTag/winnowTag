# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddUniqueIndexToFeedSubscriptions < ActiveRecord::Migration
  def self.up
    add_index :feed_subscriptions, [:feed_id, :user_id], :unique => true
  end

  def self.down
    remove_index :feed_subscriptions, :column => :feed_id
  end
end
