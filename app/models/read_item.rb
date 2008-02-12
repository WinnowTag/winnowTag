# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ReadItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed_item
  validates_presence_of :feed_item_id, :user_id
  validates_uniqueness_of :feed_item_id, :scope => :user_id
end
