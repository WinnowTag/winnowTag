# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a Tagging that has been deleted.
#
# A Tagging is never really deleted. Instead, when it's destroyed, a DeletedTagging is created
# with the attributes of the Tagging and a +deleted_at+ of <tt>Time.now</tt>. This is necessary,
# since, when a Tagging is destroyed, the classifier needs to untrain it (which is done in a
# separate process before the next classification), and the classifier needs to know the details
# of the Tagging to do so.
#
# At some point we may want to have some method that sweeps the deleted_taggings table and
# clears out old records, but we haven't needed that yet.
class DeletedTagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :user
  belongs_to :feed_item
end
