# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# NOTE: DeletedTaggings are currently not used. It is likely that this model can be deleted.
# 
# Represents a Tagging that has been deleted.
#
# A Tagging is never really deleted. Instead, when it's destroyed, a DeletedTagging is created
# with the attributes of the Tagging and a +deleted_at+ of <tt>Time.now</tt>.
class DeletedTagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :user
  belongs_to :feed_item
end
