# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class IndexExistingItems < ActiveRecord::Migration
  def self.up
    say "Adding existing items to full text index... this could take a while. (disabled)"
    # FeedItem.find(:all, :include => :content).each do |item|
    #   FeedItemTextIndex.create!(:feed_item => item)
    # end
  end

  def self.down
  end
end
