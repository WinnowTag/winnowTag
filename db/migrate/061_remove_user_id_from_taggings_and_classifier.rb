# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class RemoveUserIdFromTaggingsAndClassifier < ActiveRecord::Migration
  def self.up    
    remove_index :taggings, :name => :taggable_index
    rename_column :bayes_classifiers, :user_id, :tagger_id
    add_column :bayes_classifiers, :tagger_type, :string
    execute "UPDATE bayes_classifiers set tagger_type = 'User';"
    remove_column :taggings, :user_id
    
    add_index :taggings, [:taggable_id, :taggable_type, :deleted_at, 
                          :tagger_id, :tag_id, :tagger_type, :strength],
                         :name => "taggable_index"
  end

  def self.down
    remove_index :taggings, :name => :taggable_index
    add_column :taggings, :user_id, :integer
    execute "UPDATE taggings SET user_id = tagger_id WHERE tagger_type = 'User';"    
    execute "Delete from bayes_classifiers where tagger_type <> 'User';"
    remove_column :bayes_classifiers, :tagger_type
    rename_column :bayes_classifiers, :tagger_id, :user_id
    
    add_index :taggings, [:taggable_id, :taggable_type, :deleted_at, 
                          :user_id, :tag_id, :tagger_type, :strength],
                         :name => "taggable_index"
  end
end
