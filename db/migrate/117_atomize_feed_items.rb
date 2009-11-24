# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AtomizeFeedItems < ActiveRecord::Migration
  def self.up
    # remove auto-increment from id column
    execute "alter table feed_items modify column id integer not null;"   
    
    remove_column :feed_item_contents, :id
    execute "alter ignore table feed_item_contents add primary key(feed_item_id);"
        
    rename_column :feed_items, :time, :updated
    add_column :feed_items, :collector_link, :string
    remove_column :feed_items, :sort_title
    
    rename_column :feed_item_contents, :encoded_content, :content
  end

  def self.down
    raise IrreversibleMigration
  end
end
