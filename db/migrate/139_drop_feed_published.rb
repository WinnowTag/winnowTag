# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class DropFeedPublished < ActiveRecord::Migration
  def self.up
    remove_column :feeds, :published
  end

  def self.down
  end
end
