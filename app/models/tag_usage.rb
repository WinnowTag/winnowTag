# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents each use or request of a Tag by a User.
#
# When a tag is requested by the current user, the usage is linked to
# that user. Otherwise, the IP address of the client is recorded.
class TagUsage < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag

  validates_presence_of :tag
end
