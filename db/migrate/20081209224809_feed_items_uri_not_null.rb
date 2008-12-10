# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class FeedItemsUriNotNull < ActiveRecord::Migration
  def self.up
    change_column :feed_items, :uri, :string, :null => false
  end

  def self.down
  end
end
