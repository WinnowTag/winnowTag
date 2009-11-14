# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateFeedSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :feed_subscriptions do |t|
      t.integer :feed_id
      t.integer :user_id
      t.timestamp :created_at
    end
  end

  def self.down
    drop_table :feed_subscriptions
  end
end
