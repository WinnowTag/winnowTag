# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddFeedItemFullTextIndex < ActiveRecord::Migration
  def self.up
    execute "alter table feed_item_contents add fulltext fti_feed_item_contents (title, author, description);"
  end

  def self.down
    execute "drop index fti_feed_item_contents on feed_item_contents;"
  end
end
