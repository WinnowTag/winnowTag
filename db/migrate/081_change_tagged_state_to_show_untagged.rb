# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ChangeTaggedStateToShowUntagged < ActiveRecord::Migration
  def self.up
    add_column :views, :show_untagged, :boolean
    remove_column :views, :tagged_state
  end

  def self.down
    add_column :views, :tagged_state, :string
    remove_column :views, :show_untagged
  end
end
