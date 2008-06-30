# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddUserColumnToTaggings < ActiveRecord::Migration
  def self.up
    add_column :taggings, :user_id, :integer, :null => false
    add_column :taggings, :classifier_tagging, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :taggings, :user_id
    remove_column :taggings, :classifier_tagging
  end
end
