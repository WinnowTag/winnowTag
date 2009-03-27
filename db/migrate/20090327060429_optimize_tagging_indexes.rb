# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

class OptimizeTaggingIndexes < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:feed_item_id, :tag_id, :classifier_tagging], :unique => true

    remove_index :taggings, :name => 'user_tag_item_classifier'                         rescue puts("error deleting index")
    remove_index :taggings, :name => 'user_item_tag_classifier'                         rescue puts("error deleting index")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_feed_item_id'        rescue puts("error deleting index")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_classifier_tagging'  rescue puts("error deleting index")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_created_on'          rescue puts("error deleting index")
    remove_index :taggings, :name => 'item_tag_strength_classifier'                     rescue puts("error deleting index")
    remove_index :taggings, :name => 'index_taggings_on_user_id_and_classifier_tagging' rescue puts("error deleting index")

    execute "optimize table taggings"
  end

  def self.down
    remove_index :taggings, :column => [:feed_item_id, :tag_id, :classifier_tagging]
  end
end
