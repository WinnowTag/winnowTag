# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class DeletedTagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :user
  belongs_to :feed_item
end
