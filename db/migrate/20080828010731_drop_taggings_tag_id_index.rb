# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class DropTaggingsTagIdIndex < ActiveRecord::Migration
  def self.up
    remove_index(:taggings, :tag_id) rescue nil
  end

  def self.down
    add_index(:taggings, :tag_id)
  end
end
