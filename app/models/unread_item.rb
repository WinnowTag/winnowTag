# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class UnreadItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed_item
  validates_presence_of :user
  validates_presence_of :feed_item
  validates_uniqueness_of :user_id, :scope => :feed_item_id
end
