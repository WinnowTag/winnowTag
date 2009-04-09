# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Stores the contents for a feed item. This is the title, author,
# description and encoded content extracted from the original XML.
class FeedItemContent < ActiveRecord::Base
  set_primary_key "feed_item_id"

  belongs_to :feed_item
end
