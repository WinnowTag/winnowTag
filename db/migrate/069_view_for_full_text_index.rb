# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ViewForFullTextIndex < ActiveRecord::Migration
  def self.up
    if WinnowFeed::Migration::Migrator.using_views?
      execute "CREATE ALGORITHM = MERGE VIEW " + 
                "feed_item_contents_full_text as " +
                "select * from collector.feed_item_contents_full_text;"
    else
      say "Won't create view over feed_item_contents_full_text since this database is using concrete tables"
    end
  end

  def self.down
  end
end
