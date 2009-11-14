# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveMinTrainCountFromTaggings < ActiveRecord::Migration
  def self.up
    remove_column :taggings, :train_count
  end

  def self.down
    add_column :taggings, :train_count, :integer
  end
end
