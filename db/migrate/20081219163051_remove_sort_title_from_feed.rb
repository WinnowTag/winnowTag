# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveSortTitleFromFeed < ActiveRecord::Migration
  def self.up
    remove_column :feeds, :sort_title
  end

  def self.down
    add_column :feeds, :sort_title, :string
  end
end
