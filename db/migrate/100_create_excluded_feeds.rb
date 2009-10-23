# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateExcludedFeeds < ActiveRecord::Migration
  def self.up
    create_table :excluded_feeds do |t|
      t.column :feed_id, :integer
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :excluded_feeds
  end
end
