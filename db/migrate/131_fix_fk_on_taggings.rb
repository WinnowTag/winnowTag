# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class FixFkOnTaggings < ActiveRecord::Migration
  def self.up
    # Just removes the ON DELETE CASCADE and make sure we can't delete items with taggings
    execute "alter table taggings drop foreign key taggings_ibfk_2;"
    execute "alter table taggings add constraint taggings_feed_item foreign key (feed_item_id) references feed_items(id) ON DELETE RESTRICT"
  end

  def self.down
    execute "alter table taggings drop foreign key taggings_feed_item;"    
    execute "alter table taggings add constraint taggings_ibfk_2 foreign key (feed_item_id) references feed_items(id) ON DELETE CASCADE"
  end
end
