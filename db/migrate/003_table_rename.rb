# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class TableRename < ActiveRecord::Migration
  def self.up
    drop_table :feeds
    rename_table :seeds, :feeds
    rename_table :seed_items, :feed_items
    
    rename_column :feed_items, :seed_id, :feed_id
    rename_column :tags_seed_items, :seed_item_id, :feed_item_id
  end

  def self.down
    rename_column :tags_seed_items, :feed_item_id, :seed_item_id
    rename_column :feed_items, :feed_id, :seed_id
    rename_table :feeds, :seeds
    rename_table :feed_items, :seed_items
    
    # SBG I don't think this is actually needed but it is in
    #     the original schema so I'm putting it here incase
    create_table "feeds" do |t|
      t.column "url", :string
      t.column "title", :string, :null => true
      t.column "link", :string, :null => true
      t.column "xml_data", :longtext
      t.column "http_headers", :text
      t.column "last_retrieved", :datetime, :null => true
    end
  end
end
