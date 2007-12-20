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
    if feed
      if feed.title.blank?
        feed.url
      else
        feed.title
      end
    else
      "Unknown Feed"
    end
  end
end
