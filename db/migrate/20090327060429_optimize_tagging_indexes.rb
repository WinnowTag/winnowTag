# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class OptimizeTaggingIndexes < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:feed_item_id, :tag_id, :classifier_tagging], :unique => true

    remove_index :taggings, :name => 'user_tag_item_classifier'                         rescue say("error deleting user_tag_item_classifier")
    remove_index :taggings, :name => 'user_item_tag_classifier'                         rescue say("error deleting user_item_tag_classifier")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_feed_item_id'        rescue say("error deleting index_taggings_on_tag_id_and_feed_item_id")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_classifier_tagging'  rescue say("error deleting index_taggings_on_tag_id_and_classifier_tagging")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_created_on'          rescue say("error deleting index_taggings_on_tag_id_and_created_on")
    remove_index :taggings, :name => 'item_tag_strength_classifier'                     rescue say("error deleting item_tag_strength_classifier")
    remove_index :taggings, :name => 'index_taggings_on_user_id_and_classifier_tagging' rescue say("error deleting index_taggings_on_user_id_and_classifier_tagging")

    execute "optimize table taggings"
  end

  def self.down
    remove_index :taggings, :column => [:feed_item_id, :tag_id, :classifier_tagging]
  end
end
