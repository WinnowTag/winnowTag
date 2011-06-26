# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# Since #587 we are abandoning the views concept in favour of
# replication via atom so Winnow is free to have it's own schema
# for storing feeds and items.
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
      add_column :feeds, :duplicate_id, :integer
      add_column :feeds, :feed_items_count, :integer
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
