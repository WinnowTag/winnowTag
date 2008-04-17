# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class TextIndexingObserver < ActiveRecord::Observer
  observe :feed_item
  
  def after_create(item)
    FeedItemTextIndex.create!(:feed_item => item)
  end
end
