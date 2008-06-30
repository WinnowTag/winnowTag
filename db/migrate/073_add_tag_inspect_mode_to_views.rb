# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddTagInspectModeToViews < ActiveRecord::Migration
  def self.up
    add_column :views, :tag_inspect_mode, :boolean
  end

  def self.down
    remove_column :views, :tag_inspect_mode
  end
end
