# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddTaggingTableIndexes < ActiveRecord::Migration
  def self.up
    add_index :taggings, :deleted_at
    add_index :taggings, :tagger_id
    add_index :taggings, :taggable_id
    add_index :taggings, :tag_id
    add_index :tags, :name, :unique => true
    execute('alter table classifiers_tags add primary key (classifier_id, tag_id);')
    execute('alter table classifiers_users add primary key (classifier_id, user_id);')
  end

  def self.down
    remove_index :taggings, :deleted_at
    remove_index :taggings, :tagger_id
    remove_index :taggings, :taggable_id
    remove_index :taggings, :tag_id
    remove_index :tags, :name, :unique => true
    execute('alter table classifiers_tags add primary key (classifier_id, tag_id);')
    execute('alter table classifiers_users add primary key (classifier_id, user_id);')
  end
end
