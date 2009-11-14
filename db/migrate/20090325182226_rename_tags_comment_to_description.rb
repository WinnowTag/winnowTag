# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RenameTagsCommentToDescription < ActiveRecord::Migration
  def self.up
    rename_column :tags, :comment, :description
  end

  def self.down
    rename_column :tags, :description, :comment
  end
end
