# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class CollectionJobResult < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed
  
  def feed_title
    the_feed = if self.feed
      self.feed
    else
      Remote::Feed.find(self.feed_id) rescue nil        
    end
    
    if the_feed
      if the_feed.title.blank?
        the_feed.via
      else
        the_feed.title
      end
    else
      "Unknown Feed"
    end
  end
end
