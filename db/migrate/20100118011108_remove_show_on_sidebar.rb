# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class RemoveShowOnSidebar < ActiveRecord::Migration
  def self.up
    remove_column :tags, :show_in_sidebar
  end

  def self.down
    add_column :tags, :show_in_sidebar, :boolean,    :default => true
  end
end
