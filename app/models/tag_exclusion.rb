# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents the fact that a User has blocked all items from a Tag
# from appearing in his Winnow Items page views.
class TagExclusion < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag

  validates_presence_of :user_id, :tag_id
end
