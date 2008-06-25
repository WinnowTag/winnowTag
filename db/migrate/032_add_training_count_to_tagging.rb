# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.

# This adds a training count column to the tagging table.
#
# This column doesn't really belong as part of the model but we need
# it for debugging of classifiers.
class AddTrainingCountToTagging < ActiveRecord::Migration
  def self.up
    add_column :taggings, :train_count, :integer
  end

  def self.down
    remove_column :taggings, :train_count
  end
end
