# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class FeedSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed
  
  validates_presence_of :user_id, :feed_id
end
