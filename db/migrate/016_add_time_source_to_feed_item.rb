# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AddTimeSourceToFeedItem < ActiveRecord::Migration
  def self.up
    add_column "feed_items", "time_source", :string, :default => FeedItem::UnknownTimeSource
  end

  def self.down
    remove_column "feed_items", "time_source"
  end
end
