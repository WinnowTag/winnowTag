# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddUniqueIndexToTaggings < ActiveRecord::Migration
  def self.up
    # Create using SQL so we can automatically remove duplicates
    execute "alter ignore table taggings add unique index user_tag_item_classifier (user_id, tag_id, feed_item_id, classifier_tagging);"
    execute "alter ignore table taggings add unique index user_item_tag_classifier (user_id, feed_item_id, tag_id, classifier_tagging);"
  end

  def self.down
    remove_index :taggings, :name => "user_tag_item_classifier"
    remove_index :taggings, :name => "user_item_tag_classifier"
  end
end
