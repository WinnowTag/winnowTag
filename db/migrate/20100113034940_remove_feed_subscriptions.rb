# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class RemoveFeedSubscriptions < ActiveRecord::Migration
  def self.up
    drop_table :feed_subscriptions
  end

  def self.down
    create_table "feed_subscriptions", :force => true do |t|
      t.integer  "feed_id"
      t.integer  "user_id"
      t.datetime "created_at"
    end
  end
end
