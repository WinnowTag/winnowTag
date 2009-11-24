# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateFeedItemTextIndices < ActiveRecord::Migration
  def self.up
    execute "drop view if exists feed_item_contents_full_text;"
    execute "drop table if exists feed_item_contents_full_text;"
    
    create_table :feed_item_text_indices, :options => "ENGINE=MyISAM", :primary_key => 'feed_item_id' do |t|
      t.text :content
      t.timestamps
    end
    
    execute "create fulltext index feed_items_full_text_index on feed_item_text_indices(content)"
  end

  def self.down
    drop_table :feed_item_text_indices
  end
end
