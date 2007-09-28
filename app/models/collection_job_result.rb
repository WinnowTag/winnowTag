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
    if self.feed
      feed.title or feed.url
    else
      "Unknown Feed"
    end
  end
end
