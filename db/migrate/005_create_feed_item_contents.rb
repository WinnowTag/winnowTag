# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# This migration extracts the title, author, link, time and description
# properties out of the xml data of a feed and stores it in the 
# feed_item_contents table.  This is in a separate migration because it
# maybe a very long running migration and I want to isolate schema changes
# from data changes.
#
# Creates the feed item contents table to store contents of a feed item.
# The table also uses the MyISAM engine to allow fo text indexing at a
# later stage.
class CreateFeedItemContents < ActiveRecord::Migration
  # AR class for migrations
  class FeedItemContent < ActiveRecord::Base
    belongs_to :feed_item
  end
  class FeedItem < ActiveRecord::Base
    has_one :feed_item_content
  end
  
  def self.up
    create_table "feed_item_contents", :options => 'ENGINE=MyISAM' do |t|
      t.column "feed_item_id", :integer
      t.column "title", :text # title is here for text indexing too
      t.column "link", :string
      t.column "author", :string
      t.column "description", :longtext
    end
    
    add_index "feed_item_contents", "feed_item_id"
  end  

  def self.down
    drop_table "feed_item_contents"
  end
end
