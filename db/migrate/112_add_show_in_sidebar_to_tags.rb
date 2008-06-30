# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddShowInSidebarToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :show_in_sidebar, :boolean, :default => true
  end

  def self.down
    remove_column :tags, :show_in_sidebar
  end
end
