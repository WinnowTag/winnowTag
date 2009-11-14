# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Observes FeedItem instances in order to keep a full-text index of their
# content up-to-date.
class TextIndexingObserver < ActiveRecord::Observer
  observe :feed_item
  
  def after_create(item)
    FeedItemTextIndex.create!(:feed_item => item)
  end
end
