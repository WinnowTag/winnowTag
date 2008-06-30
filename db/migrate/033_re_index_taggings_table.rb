# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ReIndexTaggingsTable < ActiveRecord::Migration
  def self.up
#    remove_index :taggings, :name => :taggings_taggable_id_index
#    remove_index :taggings, :name => :taggings_tagger_id_index
#    remove_index :taggings, :name => :taggings_tag_id_index
#    remove_index :taggings, :name => :taggings_deleted_at_index
    
    add_index :taggings, [:tagger_id, :tagger_type, :deleted_at, 
                          :tag_id, :strength, :train_count], 
                          :name => "tagger_index"
    add_index :taggings, [:taggable_id, :taggable_type, :deleted_at, 
                          :user_id, :tag_id, :tagger_type, :strength, 
                          :train_count], :name => "taggable_index"
    execute 'optimize table taggings;'
    execute 'analyze table taggings;'
  end

  def self.down
    add_index :taggings, :taggable_id
    add_index :taggings, :tagger_id
    add_index :taggings, :tag_id
    add_index :taggings, :deleted_at
    remove_index :taggings, :name => :tagger_index
    remove_index :taggings, :name => :taggable_index
  end
end
