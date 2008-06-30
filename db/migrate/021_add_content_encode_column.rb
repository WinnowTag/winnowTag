# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddContentEncodeColumn < ActiveRecord::Migration
  def self.up
    add_column "feed_item_contents", "encoded_content", :text
    
    say "Loading content:encoded from each feed item... This could take a while"
    FeedItem.find(:all).each do |fi|
      fi.feed_item_content = nil
      fi.content
    end
  end

  def self.down
    remove_column "feed_item_contents", "encoded_content"
  end
end
