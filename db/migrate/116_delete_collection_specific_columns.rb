# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class DeleteCollectionSpecificColumns < ActiveRecord::Migration
  def self.up
    remove_column :feeds, :last_http_headers
   # remove_column :feeds, :collection_errors_count

    remove_column :feed_items, :time_source
    remove_column :feed_items, :xml_data_size
   #  remove_column :feed_items, :tokens_were_spidered
    remove_column :feed_items, :content_length
    remove_column :feed_items, :unique_id
    add_column :feed_items, :title, :string

    execute "update feed_items set title = (select title from feed_item_contents where feed_item_id = feed_items.id limit 1)"
    
    remove_column :feed_item_contents, :created_on
    remove_column :feed_item_contents, :link
    remove_column :feed_item_contents, :title
    remove_column :feed_item_contents, :description
    
  end

  def self.down
    raise IrreversibleMigration
  end
end
