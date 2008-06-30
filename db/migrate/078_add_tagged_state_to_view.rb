# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddTaggedStateToView < ActiveRecord::Migration
  def self.up
    add_column :views, :tagged_state, :string
  end

  def self.down
    remove_column :views, :tagged_state
  end
end
