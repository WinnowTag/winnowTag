# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module Remote
  # Represents a collection job in the Collector.
  class CollectionJob < CollectorResource
    self.site += "/feeds/:feed_id"
  end
end