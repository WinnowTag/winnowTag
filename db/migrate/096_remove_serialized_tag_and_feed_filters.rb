# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveSerializedTagAndFeedFilters < ActiveRecord::Migration
  def self.up
    remove_column :views, :tag_filter
    remove_column :views, :feed_filter
  end

  def self.down
    add_column :views, :tag_filter, :text
    add_column :views, :feed_filter, :text
  end
end
