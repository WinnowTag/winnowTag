# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddFiltersAndStateToViews < ActiveRecord::Migration
  def self.up
    add_column :views, :text_filter, :text
    add_column :views, :tag_filter, :text
    add_column :views, :feed_filter, :text
    add_column :views, :state, :string
  end

  def self.down
    remove_column :views, :text_filter
    remove_column :views, :tag_filter
    remove_column :views, :feed_filter
    remove_column :views, :state
  end
end
