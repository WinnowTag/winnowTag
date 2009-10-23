# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class FeedItemsIdAutoIncrement < ActiveRecord::Migration
  def self.up
    execute "alter table feed_items change column id id integer auto_increment"
  end

  def self.down
  end
end
