# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Since #587 we are abandoning the views concept in favour of
# replication via atom so Winnow is free to have it's own schema
# for storing feeds and items.
#
class RecreateFeedsTablesIfUsingViews < ActiveRecord::Migration
  def self.up
    if using_views?
      # make sure views are up to date
      execute 'drop table if exists feeds, feed_items, feed_item_contents, feed_item_xml_data, feed_xml_datas, feed_item_tokens_containers, random_backgrounds, tokens;'
      execute 'create or replace algorithm=merge view feeds as select * from collector.feeds;'
      execute 'create or replace algorithm=merge view feed_items as select * from collector.feed_items;'
      execute 'create or replace algorithm=merge view feed_item_contents as select * from collector.feed_item_contents;'
      execute 'create or replace algorithm=merge view feed_item_xml_data as select * from collector.feed_item_xml_data;'
      execute 'create or replace algorithm=merge view feed_xml_datas as select * from collector.feed_xml_datas;'
      execute 'create or replace algorithm=merge view random_backgrounds as select * from collector.random_backgrounds;'
      execute 'create or replace algorithm=merge view tokens as select * from collector.tokens;'

      # Rename the views that we want to recreate tables for
      rename_table :feeds, :feeds_view
      rename_table :feed_items, :feed_items_view
      rename_table :feed_item_contents, :feed_item_contents_view

      # reproduce the original table formats
      execute "create table feeds like collector.feeds;"
      execute "create table feed_items like collector.feed_items;"
      execute "create table feed_item_contents like collector.feed_item_contents;"

      # copy the data from the views
      execute "insert into feeds select * from feeds_view;"
      execute "insert into feed_items select * from feed_items_view;"
      execute "insert into feed_item_contents select * from feed_item_contents_view;"
        
      execute "drop view if exists feeds_view, feed_items_view, feed_item_contents_view, feed_item_xml_data, feed_xml_datas, random_backgrounds, tokens;"
      
      # delete the winnow_feed_schema_info table
      drop_table :winnow_feed_schema_info
     else
      say "Not using views - no action required"
     end
  end

  def self.down
    raise IrrevesibleMigration
  end
  
  def self.using_views?
    begin
      ActiveRecord::Base.connection.select_one("SHOW CREATE VIEW tokens;")
      return true
    rescue
      return false
    end
  end
end
