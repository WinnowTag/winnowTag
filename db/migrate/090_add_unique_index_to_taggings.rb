# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddUniqueIndexToTaggings < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:user_id, :tag_id, :feed_item_id, :classifier_tagging], :name => "user_tag_item_classifier", :unique => true
    add_index :taggings, [:user_id, :feed_item_id, :tag_id, :classifier_tagging], :name => "user_item_tag_classifier", :unique => true
  end

  def self.down
    remove_index :taggings, :name => "user_tag_item_classifier"
    remove_index :taggings, :name => "user_item_tag_classifier"
  end
end
