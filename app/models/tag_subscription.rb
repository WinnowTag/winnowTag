# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a User subscribing to a Tag. In other words, the User wants
# to see content from this Tag. TagSubscription might be considered the
# opposite of TagExclusion.
class TagSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
  
  validates_presence_of :user_id, :tag_id
end
