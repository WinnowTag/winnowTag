# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a User subscribing to a Feed. In other words, the User wants
# to see content from this Feed.
class FeedSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed
  
  validates_presence_of :user_id, :feed_id
end
