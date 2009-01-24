# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class TagUsage < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag

  validates_presence_of :tag
end
