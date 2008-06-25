# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class TagSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
  
  validates_presence_of :user_id, :tag_id
end
