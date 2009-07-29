# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents the fact that a User has blocked all items from a Feed
# from appearing in his Winnow Items page views. FeedExclusion might be
# considered the opposite of FeedSubscription.
class FeedExclusion < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed

  validates_presence_of :user_id, :feed_id
end
