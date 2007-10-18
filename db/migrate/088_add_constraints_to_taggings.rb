# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddConstraintsToTaggings < ActiveRecord::Migration
  def self.up    
    change_column :taggings, :tag_id, :integer, :null => false
    change_column :taggings, :feed_item_id, :integer, :null => false
    change_column :taggings, :strength, :float, :null => false
    
    # Might have old indexes in place
    execute "alter ignore table taggings drop index tagger_index;"
    execute "alter ignore table taggings drop index taggable_index;"
    
    # First do some cleaning up    
    execute "delete from taggings where user_id = 0;"
    execute "delete from taggings where tag_id not in (select id from tags);"
    
    execute "alter table taggings add foreign key (tag_id) references tags(id) on delete cascade;"
    execute "alter table taggings add foreign key (user_id) references users(id) on delete cascade;"
    # Can't put one on feed_items because it is not an InnoDB table
    # execute "alter table taggings add foreign key (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
  end
end
